defmodule GibberingTalesWeb.HUD do
  @moduledoc """
  Populates a `%GibberingEngine.HUD{}` from the current `Engine.State`.

  Called after each state update in `GameLive` to produce the `@hud` assign.
  Role-gated: player gets action buttons from the ruleset; DM gets none.

  Lives in `gibbering_tales_web` (not `gibbering_tales`) because it reads
  `GibberingTalesWeb.Engine.State`, which is defined in this app.
  """

  alias GibberingEngine.HUD
  alias GibberingEngine.HUD.{Action, Overlay, StatusItem}
  alias GibberingTalesWeb.Engine.State

  @doc """
  Build a `%GibberingEngine.HUD{}` for the given state and viewer role.

  `viewer_role` is `:player` or `:dm`. DM always receives an empty `action_bar`;
  only players get ruleset-driven action buttons.
  """
  @spec build(State.t(), :player | :dm) :: HUD.t()
  def build(%State{} = state, viewer_role) do
    active_id = State.active_hero_id(state)
    active_entity = active_id && Map.get(state.actors, active_id)

    %HUD{
      action_bar: build_action_bar(state, active_entity, viewer_role),
      overlays: build_overlays(state),
      prompts: [],
      status_strip: build_status_strip(state)
    }
  end

  # ---------------------------------------------------------------------------
  # Private builders
  # ---------------------------------------------------------------------------

  defp build_action_bar(_state, _active_entity, :dm), do: []
  defp build_action_bar(_state, nil, :player), do: []

  defp build_action_bar(state, active_entity, :player) do
    state.ruleset.action_buttons(active_entity, state)
    |> Enum.map(fn btn ->
      %Action{
        label: btn.label,
        sublabel: Map.get(btn, :sublabel),
        event: btn.event,
        value: btn.value,
        enabled: not Map.get(btn, :disabled, false),
        selected: false
      }
    end)
  end

  defp build_overlays(%State{valid_moves: moves, valid_move_costs: costs, valid_targets: targets}) do
    move_overlays =
      (moves || [])
      |> Enum.map(fn {x, y} ->
        kind =
          case Map.get(costs || %{}, {x, y}, :normal) do
            :difficult -> :move_difficult
            _ -> :move_normal
          end

        %Overlay{kind: kind, x: x, y: y}
      end)

    target_overlays =
      (targets || [])
      |> Enum.map(fn entity_id ->
        %Overlay{kind: :attack_target, entity_id: entity_id}
      end)

    move_overlays ++ target_overlays
  end

  defp build_status_strip(%State{actors: actors}) do
    actors
    |> Enum.flat_map(fn {entity_id, entity} ->
      (entity.conditions || [])
      |> Enum.map(fn condition_id ->
        %StatusItem{
          entity_id: entity_id,
          condition_id: condition_id,
          label: condition_id |> Atom.to_string() |> String.replace("_", " ")
        }
      end)
    end)
  end
end
