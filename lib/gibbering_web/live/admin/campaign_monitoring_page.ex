defmodule GibberingWeb.Admin.CampaignMonitoringPage do
  @moduledoc "LiveDashboard custom page showing active campaign GenServer processes."

  use Phoenix.LiveDashboard.PageBuilder

  import Ecto.Query

  alias Gibbering.{Admin, Campaign, Repo}
  alias Gibbering.Engine.SceneServer

  @impl true
  def menu_link(_, _), do: {:ok, "Campaigns"}

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, actor_id: session["support_user_id"], rows: fetch_rows())}
  end

  @impl true
  def handle_refresh(socket) do
    {:noreply, assign(socket, rows: fetch_rows())}
  end

  @impl true
  def handle_event("force_close", %{"id" => id}, socket) do
    campaign_id = String.to_integer(id)

    Admin.force_close_campaign(
      socket.assigns.actor_id,
      campaign_id,
      "Force closed via admin dashboard"
    )

    {:noreply, assign(socket, rows: fetch_rows())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @rows == [] do %>
        <p style="color: #9ca3af; font-size: 0.875rem; padding: 2rem 0;">
          No active campaign sessions.
        </p>
      <% else %>
        <table style="width: 100%; border-collapse: collapse; font-size: 0.875rem;">
          <thead>
            <tr style="color: #9ca3af; font-size: 0.75rem; text-transform: uppercase; border-bottom: 1px solid #374151;">
              <th style="text-align: left; padding: 0.5rem 1rem;">Campaign</th>
              <th style="text-align: left; padding: 0.5rem 1rem;">PID</th>
              <th style="text-align: right; padding: 0.5rem 1rem;">Memory (KB)</th>
              <th style="text-align: right; padding: 0.5rem 1rem;">Queue</th>
              <th style="text-align: right; padding: 0.5rem 1rem;">Entities</th>
              <th style="text-align: right; padding: 0.5rem 1rem;">Phase</th>
              <th style="padding: 0.5rem 1rem;"></th>
            </tr>
          </thead>
          <tbody>
            <%= for row <- @rows do %>
              <tr style="border-bottom: 1px solid #374151;">
                <td style="padding: 0.5rem 1rem;">
                  <strong>{row.name || "Campaign #{row.campaign_id}"}</strong>
                  <span style="color: #6b7280; font-size: 0.75rem; margin-left: 0.5rem;">
                    ##{row.campaign_id}
                  </span>
                </td>
                <td style="padding: 0.5rem 1rem; font-family: monospace; font-size: 0.75rem; color: #9ca3af;">
                  {inspect(row.pid)}
                </td>
                <td style="padding: 0.5rem 1rem; text-align: right; font-family: monospace;">
                  {Float.round(row.memory / 1024, 1)}
                </td>
                <td style="padding: 0.5rem 1rem; text-align: right; font-family: monospace;">
                  {row.message_queue_len}
                </td>
                <td style="padding: 0.5rem 1rem; text-align: right;">{row.entity_count}</td>
                <td style="padding: 0.5rem 1rem; text-align: right; font-size: 0.75rem; color: #9ca3af; font-family: monospace;">
                  {row.phase}
                </td>
                <td style="padding: 0.5rem 1rem; text-align: right;">
                  <button
                    phx-click="force_close"
                    phx-value-id={row.campaign_id}
                    data-confirm={"Force close campaign #{row.campaign_id}?"}
                    style="background: #7f1d1d; color: white; border: none; border-radius: 4px; padding: 0.25rem 0.75rem; font-size: 0.75rem; cursor: pointer;"
                  >
                    Force Close
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp fetch_rows do
    active_ids =
      Registry.select(Gibbering.GameRegistry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])

    campaign_names =
      if active_ids == [] do
        %{}
      else
        ids = Enum.map(active_ids, &elem(&1, 0))

        from(c in Campaign, where: c.id in ^ids, select: {c.id, c.name})
        |> Repo.all()
        |> Map.new()
      end

    Enum.map(active_ids, fn {campaign_id, pid} ->
      proc = :erlang.process_info(pid, [:memory, :message_queue_len])
      {entity_count, phase} = try_get_scene_info(campaign_id)

      %{
        campaign_id: campaign_id,
        name: Map.get(campaign_names, campaign_id),
        pid: pid,
        memory: proc[:memory] || 0,
        message_queue_len: proc[:message_queue_len] || 0,
        entity_count: entity_count,
        phase: phase
      }
    end)
    |> Enum.sort_by(& &1.campaign_id)
  end

  defp try_get_scene_info(campaign_id) do
    state = SceneServer.get_state(campaign_id)
    {map_size(state.entities), state.phase}
  rescue
    _ -> {"?", "?"}
  end
end
