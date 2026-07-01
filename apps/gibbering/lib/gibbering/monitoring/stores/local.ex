defmodule Gibbering.Monitoring.Stores.Local do
  @moduledoc """
  MetricsStore adapter backed by an ETS ring buffer (5-min window, ~1 sample/10s)
  and periodic DB snapshots (~60s). Emits PubSub strain alerts on `system:admin`.

  Polls active campaigns from GameRegistry every 10 seconds and subscribes to each
  campaign's game topic. Scene info (entity count and phase) is updated from
  `%EventBatch{}` arrivals rather than calling `SceneServer.get_state/1`.
  Snapshots ETS buffer to DB every 60 seconds.
  Prunes snapshots older than 7 days every hour.
  """

  use GenServer

  @behaviour GibberingEngine.Monitoring.MetricsStore

  import Ecto.Query

  alias Gibbering.{Repo, PubSub}
  alias GibberingEngine.EventBus
  alias GibberingEngine.Events.EventBatch
  alias GibberingEngine.Events.SessionEnded
  alias Gibbering.Monitoring.CampaignMetricSnapshot

  @ets_table :gibbering_metrics_buffer
  @scene_info_table :gibbering_scene_info
  # 5 minutes in milliseconds
  @buffer_window_ms 5 * 60 * 1000
  @poll_interval_ms 10_000
  @snapshot_interval_ms 60_000
  @prune_interval_ms 60 * 60_000
  @strain_memory_bytes 100 * 1024 * 1024
  @strain_queue_depth 500
  @strain_window_s 10

  # ---------------------------------------------------------------------------
  # Public API (MetricsStore behaviour)
  # ---------------------------------------------------------------------------

  @impl GibberingEngine.Monitoring.MetricsStore
  def record(campaign_id, metric, value) do
    now_ms = System.system_time(:millisecond)
    cutoff_ms = now_ms - @buffer_window_ms

    :ets.insert(@ets_table, {{campaign_id, metric, now_ms}, value})

    # Prune entries outside the 5-min window for this campaign+metric
    match_spec = [
      {{{:"$1", :"$2", :"$3"}, :_},
       [{:==, :"$1", campaign_id}, {:==, :"$2", metric}, {:<, :"$3", cutoff_ms}], [true]}
    ]

    :ets.select_delete(@ets_table, match_spec)

    :ok
  end

  @impl GibberingEngine.Monitoring.MetricsStore
  def history(campaign_id, metric) do
    match_spec = [
      {{{:"$1", :"$2", :"$3"}, :"$4"}, [{:==, :"$1", campaign_id}, {:==, :"$2", metric}],
       [{{:"$3", :"$4"}}]}
    ]

    @ets_table
    |> :ets.select(match_spec)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {ts_ms, value} ->
      dt = DateTime.from_unix!(div(ts_ms, 1000))
      {dt, value}
    end)
  end

  @impl GibberingEngine.Monitoring.MetricsStore
  def scene_snapshot(campaign_id) do
    case :ets.lookup(@scene_info_table, campaign_id) do
      [{^campaign_id, entity_count, phase}] -> {entity_count, phase}
      [] -> {"?", "?"}
    end
  end

  # ---------------------------------------------------------------------------
  # GenServer
  # ---------------------------------------------------------------------------

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    :ets.new(@ets_table, [:named_table, :public, :ordered_set])
    :ets.new(@scene_info_table, [:named_table, :public, :set])
    schedule_poll()
    schedule_snapshot()
    schedule_prune()
    {:ok, %{strain_state: %{}, subscribed_campaigns: MapSet.new()}}
  end

  @impl GenServer
  def handle_info(:poll, state) do
    active = active_campaigns()
    state = update_subscriptions(active, state)
    strain_state = poll_and_detect_strain(active, state.strain_state)
    schedule_poll()
    {:noreply, %{state | strain_state: strain_state}}
  end

  def handle_info(:snapshot, state) do
    snapshot_to_db()
    schedule_snapshot()
    {:noreply, state}
  end

  def handle_info(:prune, state) do
    prune_old_snapshots()
    schedule_prune()
    {:noreply, state}
  end

  def handle_info(%EventBatch{state_snapshot: snapshot, events: events}, state) do
    campaign_id = snapshot.campaign_id

    if Enum.any?(events, &match?(%SessionEnded{}, &1)) do
      EventBus.unsubscribe("game:#{campaign_id}")
      :ets.delete(@scene_info_table, campaign_id)

      {:noreply,
       %{state | subscribed_campaigns: MapSet.delete(state.subscribed_campaigns, campaign_id)}}
    else
      :ets.insert(
        @scene_info_table,
        {campaign_id, map_size(snapshot.actors), Gibbering.Engine.State.phase(snapshot)}
      )

      {:noreply, state}
    end
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp schedule_poll, do: Process.send_after(self(), :poll, @poll_interval_ms)
  defp schedule_snapshot, do: Process.send_after(self(), :snapshot, @snapshot_interval_ms)
  defp schedule_prune, do: Process.send_after(self(), :prune, @prune_interval_ms)

  defp active_campaigns do
    Registry.select(Gibbering.GameRegistry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

  defp update_subscriptions(active_campaigns, state) do
    active_ids = MapSet.new(active_campaigns, fn {id, _pid} -> id end)
    subscribed = state.subscribed_campaigns

    MapSet.difference(active_ids, subscribed)
    |> Enum.each(&EventBus.subscribe("game:#{&1}"))

    dropped_ids = MapSet.difference(subscribed, active_ids)
    Enum.each(dropped_ids, &EventBus.unsubscribe("game:#{&1}"))
    Enum.each(dropped_ids, &:ets.delete(@scene_info_table, &1))

    %{state | subscribed_campaigns: active_ids}
  end

  defp poll_and_detect_strain(active_campaigns, strain_state) do
    now = DateTime.utc_now()

    Enum.reduce(active_campaigns, strain_state, fn {campaign_id, pid}, acc ->
      proc = :erlang.process_info(pid, [:memory, :message_queue_len])
      {entity_count, _phase} = scene_snapshot(campaign_id)

      memory = proc[:memory] || 0
      queue_depth = proc[:message_queue_len] || 0

      record(campaign_id, "memory_bytes", memory)
      record(campaign_id, "queue_depth", queue_depth)

      if is_integer(entity_count) do
        record(campaign_id, "entity_count", entity_count)
      end

      acc
      |> check_strain(campaign_id, :memory, memory, @strain_memory_bytes, now)
      |> check_strain(campaign_id, :queue_depth, queue_depth, @strain_queue_depth, now)
    end)
  end

  defp check_strain(strain_state, campaign_id, key, value, threshold, now) do
    strain_key = {campaign_id, key}

    if value >= threshold do
      case Map.get(strain_state, strain_key) do
        nil ->
          Map.put(strain_state, strain_key, now)

        first_at ->
          if DateTime.diff(now, first_at) >= @strain_window_s do
            maybe_broadcast_strain(campaign_id, key, value, threshold)
          end

          strain_state
      end
    else
      Map.delete(strain_state, strain_key)
    end
  end

  defp maybe_broadcast_strain(campaign_id, metric, value, threshold) do
    Phoenix.PubSub.broadcast(PubSub, "system:admin", %{
      event: :campaign_strain,
      campaign_id: campaign_id,
      metric: metric,
      value: value,
      threshold: threshold
    })
  end

  defp snapshot_to_db do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    match_spec = [
      {{{:"$1", :"$2", :"$3"}, :"$4"}, [], [{{:"$1", :"$2", :"$3", :"$4"}}]}
    ]

    rows = :ets.select(@ets_table, match_spec)

    Enum.each(rows, fn {campaign_id, metric, ts_ms, value} ->
      recorded_at = DateTime.from_unix!(div(ts_ms, 1000)) |> DateTime.truncate(:second)

      Repo.insert_all(CampaignMetricSnapshot, [
        %{
          campaign_id: campaign_id,
          metric: metric,
          value: value / 1,
          recorded_at: recorded_at,
          inserted_at: now
        }
      ])
    end)
  rescue
    _ -> :ok
  end

  defp prune_old_snapshots do
    cutoff = DateTime.utc_now() |> DateTime.add(-7 * 24 * 3600) |> DateTime.truncate(:second)

    from(s in CampaignMetricSnapshot, where: s.recorded_at < ^cutoff)
    |> Repo.delete_all()
  rescue
    _ -> :ok
  end
end
