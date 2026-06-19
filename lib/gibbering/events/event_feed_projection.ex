defmodule Gibbering.Events.EventFeedProjection do
  @moduledoc """
  Pure projection that derives the effective visibility of each event by folding
  a log in append order.

  The event log is append-only. `LogEntryRevealed` does not mutate the original
  event — it marks the referenced event as `:revealed` in the derived map.
  `LogEntryHidden` retracts that promotion (back to `:dm_only`). A subsequent
  `LogEntryRevealed` can restore it. The DM can toggle freely.

  Only `:dm_only` events can be promoted via `LogEntryRevealed`. Naturally
  `:public` events cannot be hidden.

  ## Usage

      overrides = EventFeedProjection.fold(events)
      effective_vis = Map.get(overrides, event.event_id, event.visibility)
  """

  alias Gibbering.Events.Scene.{LogEntryRevealed, LogEntryHidden}

  @type overrides :: %{String.t() => :revealed | :dm_only}

  @doc """
  Folds a list of events (oldest first) and returns a map of
  `%{event_id => derived_visibility}` for events whose visibility has been
  overridden by a `LogEntryRevealed` or `LogEntryHidden` event.

  Events not present in the returned map retain their struct-level `visibility`.
  """
  @spec fold([struct()]) :: overrides()
  def fold(events) do
    Enum.reduce(events, %{}, fn
      %LogEntryRevealed{original_event_id: id}, acc ->
        Map.put(acc, id, :revealed)

      %LogEntryHidden{original_event_id: id}, acc ->
        Map.put(acc, id, :dm_only)

      _other, acc ->
        acc
    end)
  end

  @doc """
  Returns the effective visibility of a single event, given a pre-computed
  overrides map from `fold/1`.
  """
  @spec effective_visibility(struct(), overrides()) :: :public | :dm_only | :revealed
  def effective_visibility(event, overrides) do
    Map.get(overrides, event.event_id, event.visibility)
  end

  @doc """
  Returns `{event, effective_visibility}` pairs for events visible in the player
  feed (`:public` or `:revealed`), in append order.
  """
  @spec player_visible([struct()]) :: [{struct(), :public | :revealed}]
  def player_visible(events) do
    overrides = fold(events)

    events
    |> Enum.map(fn event -> {event, effective_visibility(event, overrides)} end)
    |> Enum.filter(fn {_event, vis} -> vis in [:public, :revealed] end)
  end
end
