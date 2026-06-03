defmodule GibberingWeb.GameLive do
  use GibberingWeb, :live_view

  alias Gibbering.Engine.{GameServer, State}

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game_id = String.to_integer(game_id)

    case Registry.lookup(Gibbering.GameRegistry, game_id) do
      [] -> GameServer.start_link(game_id)
      _ -> :ok
    end

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Gibbering.PubSub, GameServer.topic(game_id))
    end

    state = GameServer.get_state(game_id)

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(:game_state, state)
     |> assign(:valid_targets, [])
     |> assign(:log, [])}
  end

  @impl true
  def handle_event("select_entity", %{"id" => id}, socket) do
    id = String.to_integer(id)
    new_state = GameServer.select_entity(socket.assigns.game_id, id)
    targets = Gibbering.Engine.Rules.valid_targets(new_state, id)
    {:noreply, assign(socket, game_state: new_state, valid_targets: targets)}
  end

  @impl true
  def handle_event("move", %{"x" => x, "y" => y}, socket) do
    new_state = GameServer.move_entity(socket.assigns.game_id, String.to_integer(x), String.to_integer(y))
    active = State.active_hero_id(new_state)
    targets = if active, do: Gibbering.Engine.Rules.valid_targets(new_state, active), else: []
    {:noreply, assign(socket, game_state: new_state, valid_targets: targets)}
  end

  @impl true
  def handle_event("attack", %{"id" => target_id}, socket) do
    target_id = String.to_integer(target_id)
    target_name = socket.assigns.game_state.entities[target_id].name
    new_state = GameServer.attack_entity(socket.assigns.game_id, target_id)

    log_entry =
      if Map.has_key?(new_state.entities, target_id) do
        hp = new_state.entities[target_id].hp
        "#{target_name} hit! #{hp} HP remaining."
      else
        "#{target_name} destroyed!"
      end

    {:noreply,
     socket
     |> assign(game_state: new_state, valid_targets: [])
     |> update(:log, fn log -> [log_entry | Enum.take(log, 9)] end)}
  end

  @impl true
  def handle_event("end_turn", _, socket) do
    new_state = GameServer.end_turn(socket.assigns.game_id)
    {:noreply, assign(socket, game_state: new_state, valid_targets: [])}
  end

  @impl true
  def handle_info({:state_updated, new_state}, socket) do
    {:noreply, assign(socket, game_state: new_state)}
  end

  defp tile_color("grass"), do: "#4a7c59"
  defp tile_color("stone"), do: "#6b6b6b"
  defp tile_color("rubble"), do: "#8b7355"
  defp tile_color(_), do: "#4a7c59"

  defp hp_bar_color(hp, max_hp) when max_hp > 0 do
    pct = hp / max_hp
    cond do
      pct > 0.6 -> "#2ecc71"
      pct > 0.3 -> "#f39c12"
      true -> "#e74c3c"
    end
  end
  defp hp_bar_color(_, _), do: "#e74c3c"

  defp entity_color(%{type: "hero", name: name}) do
    if String.contains?(name, "Warrior"), do: "#3498db", else: "#9b59b6"
  end
  defp entity_color(%{type: "object"}), do: "#7f8c8d"
  defp entity_color(_), do: "#e74c3c"
end
