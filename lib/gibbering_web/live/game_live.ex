defmodule GibberingWeb.GameLive do
  use GibberingWeb, :live_view

  alias Gibbering.Engine.{GameServer, State}

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game_id = String.to_integer(game_id)

    case ensure_game_server(game_id) do
      :ok ->
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

      {:error, reason} ->
        {:ok,
         socket
         |> put_flash(:error, "Game #{game_id} could not be loaded: #{inspect(reason)}")
         |> redirect(to: "/")}
    end
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
    new_state =
      GameServer.move_entity(socket.assigns.game_id, String.to_integer(x), String.to_integer(y))

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

  # ---------------------------------------------------------------------------
  # GameServer lifecycle
  # ---------------------------------------------------------------------------

  # Uses GenServer.start/3 (not start_link) so a crash in GameServer.init does
  # not propagate an exit signal to the LiveView process.
  defp ensure_game_server(game_id) do
    case Registry.lookup(Gibbering.GameRegistry, game_id) do
      [_] ->
        :ok

      [] ->
        case GenServer.start(Gibbering.Engine.GameServer, game_id,
               name: {:via, Registry, {Gibbering.GameRegistry, game_id}}
             ) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  # ---------------------------------------------------------------------------
  # Tile helpers (DST palette)
  # ---------------------------------------------------------------------------

  defp tile_fill("grass"), do: "#3d6b45"
  defp tile_fill("stone"), do: "#555555"
  defp tile_fill("rubble"), do: "#7a6248"
  defp tile_fill(_), do: "#3d6b45"

  defp tile_stroke("grass"), do: "#2a4d30"
  defp tile_stroke("stone"), do: "#383838"
  defp tile_stroke("rubble"), do: "#4d3d2c"
  defp tile_stroke(_), do: "#2a4d30"

  defp hp_bar_color(hp, max_hp) when max_hp > 0 do
    pct = hp / max_hp

    cond do
      pct > 0.6 -> "#2ecc71"
      pct > 0.3 -> "#f39c12"
      true -> "#e74c3c"
    end
  end

  defp hp_bar_color(_, _), do: "#e74c3c"

  defp sprite_color("warrior"), do: "#4a6fa5"
  defp sprite_color("wizard"), do: "#7b5ea7"
  defp sprite_color("rock"), do: "#787878"
  defp sprite_color(_), do: "#7f8c8d"

  # ---------------------------------------------------------------------------
  # Entity sprite components — inline SVG, DST-style ink aesthetic.
  # Each sprite is a 64×64 box; feet/shadow sit at local y≈60.
  # ---------------------------------------------------------------------------

  defp entity_sprite(%{sprite: "warrior"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="18" ry="6" fill="rgba(0,0,0,0.4)" />
      <rect x="20" y="44" width="9" height="16" rx="2" fill="#3a5075" stroke="#111" stroke-width="2" />
      <rect x="35" y="44" width="9" height="16" rx="2" fill="#3a5075" stroke="#111" stroke-width="2" />
      <rect x="17" y="22" width="30" height="24" rx="3" fill="#4a6fa5" stroke="#111" stroke-width="2" />
      <rect x="17" y="42" width="30" height="4" fill="#8b6020" stroke="#111" stroke-width="1" />
      <ellipse cx="13" cy="27" rx="6" ry="8" fill="#3a5075" stroke="#111" stroke-width="2" />
      <ellipse cx="51" cy="27" rx="6" ry="8" fill="#3a5075" stroke="#111" stroke-width="2" />
      <ellipse cx="32" cy="14" rx="11" ry="11" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <path d="M21,15 Q32,2 43,15" fill="#3a5075" stroke="#111" stroke-width="2" />
      <circle cx="28" cy="14" r="1.5" fill="#111" />
      <circle cx="36" cy="14" r="1.5" fill="#111" />
    </g>
    """
  end

  defp entity_sprite(%{sprite: "wizard"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="14" ry="5" fill="rgba(0,0,0,0.4)" />
      <path d="M26,22 L20,58 L44,58 L38,22 Z" fill="#6040a0" stroke="#111" stroke-width="2" />
      <line x1="32" y1="26" x2="30" y2="54" stroke="#7a55b8" stroke-width="1.5" />
      <rect
        x="26"
        y="19"
        width="12"
        height="6"
        rx="2"
        fill="#7b5ea7"
        stroke="#111"
        stroke-width="1.5"
      />
      <ellipse cx="32" cy="14" rx="10" ry="10" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <circle cx="28" cy="14" r="1.5" fill="#111" />
      <circle cx="36" cy="14" r="1.5" fill="#111" />
      <ellipse cx="32" cy="8" rx="14" ry="3" fill="#3b2060" stroke="#111" stroke-width="1.5" />
      <polygon points="32,0 19,9 45,9" fill="#3b2060" stroke="#111" stroke-width="1.5" />
      <line x1="47" y1="10" x2="45" y2="58" stroke="#7a5820" stroke-width="3" stroke-linecap="round" />
      <circle cx="47" cy="8" r="5" fill="#c090e8" stroke="#111" stroke-width="1.5" />
    </g>
    """
  end

  defp entity_sprite(%{sprite: "rock"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="22" ry="7" fill="rgba(0,0,0,0.4)" />
      <polygon
        points="12,56 8,36 16,20 34,14 52,20 56,38 48,56"
        fill="#787878"
        stroke="#111"
        stroke-width="2.5"
      />
      <polygon points="20,52 16,36 24,24 40,22 48,34 44,52" fill="#6a6a6a" stroke="none" />
      <path
        d="M26,24 L22,40 L26,52"
        stroke="#505050"
        stroke-width="2"
        fill="none"
        stroke-linecap="round"
      />
      <polygon points="44,56 42,46 54,44 56,54" fill="#888" stroke="#111" stroke-width="2" />
    </g>
    """
  end

  defp entity_sprite(assigns) do
    ~H"""
    <rect
      x={@x + 8}
      y={@y + 8}
      width="48"
      height="48"
      rx="4"
      fill={sprite_color(@sprite)}
      stroke="#111"
      stroke-width="2"
    />
    """
  end

  # ---------------------------------------------------------------------------
  # Tile decoration components
  # ---------------------------------------------------------------------------

  defp decoration_sprite(%{decoration: "dead_tree"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="10" ry="3" fill="rgba(0,0,0,0.3)" />
      <rect
        x="29"
        y="28"
        width="6"
        height="32"
        rx="2"
        fill="#4a3018"
        stroke="#111"
        stroke-width="1.5"
      />
      <path
        d="M29,58 Q20,62 16,60"
        stroke="#4a3018"
        stroke-width="3"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M35,58 Q44,62 48,60"
        stroke="#4a3018"
        stroke-width="3"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M31,35 Q17,28 11,20"
        stroke="#4a3018"
        stroke-width="4"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M11,20 Q7,13 9,9"
        stroke="#4a3018"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M33,38 Q47,30 53,22"
        stroke="#4a3018"
        stroke-width="3.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M53,22 Q57,15 55,11"
        stroke="#4a3018"
        stroke-width="2"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M32,30 Q27,22 25,15"
        stroke="#4a3018"
        stroke-width="3"
        fill="none"
        stroke-linecap="round"
      />
    </g>
    """
  end

  defp decoration_sprite(%{decoration: "rock_cluster"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="30" cy="60" rx="18" ry="5" fill="rgba(0,0,0,0.3)" />
      <polygon
        points="16,56 12,42 22,32 38,32 46,42 42,56"
        fill="#787878"
        stroke="#111"
        stroke-width="2"
      />
      <polygon points="38,56 36,46 48,42 52,52" fill="#888" stroke="#111" stroke-width="1.5" />
      <ellipse cx="18" cy="56" rx="5" ry="3" fill="#6a6a6a" stroke="#111" stroke-width="1" />
    </g>
    """
  end

  defp decoration_sprite(%{decoration: "bones"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="26" cy="52" rx="7" ry="6" fill="#d8d0b0" stroke="#111" stroke-width="1.5" />
      <rect x="23" y="56" width="6" height="5" rx="1" fill="#d8d0b0" stroke="#111" stroke-width="1" />
      <line x1="24" y1="50" x2="48" y2="44" stroke="#d8d0b0" stroke-width="3" stroke-linecap="round" />
      <circle cx="24" cy="50" r="3" fill="#d8d0b0" stroke="#111" stroke-width="1" />
      <circle cx="48" cy="44" r="3" fill="#d8d0b0" stroke="#111" stroke-width="1" />
      <line
        x1="30"
        y1="58"
        x2="50"
        y2="56"
        stroke="#d8d0b0"
        stroke-width="2.5"
        stroke-linecap="round"
      />
      <circle cx="30" cy="58" r="2.5" fill="#d8d0b0" stroke="#111" stroke-width="1" />
      <circle cx="50" cy="56" r="2.5" fill="#d8d0b0" stroke="#111" stroke-width="1" />
    </g>
    """
  end

  defp decoration_sprite(%{decoration: "grass_tuft"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <path
        d="M22,58 Q18,50 16,42"
        stroke="#4a7830"
        stroke-width="2"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M27,58 Q23,48 21,38"
        stroke="#5a8a40"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M32,58 Q31,46 32,34"
        stroke="#6a9a4a"
        stroke-width="3"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M37,58 Q41,47 43,38"
        stroke="#5a8a40"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M42,58 Q46,50 48,42"
        stroke="#4a7830"
        stroke-width="2"
        fill="none"
        stroke-linecap="round"
      />
    </g>
    """
  end

  defp decoration_sprite(assigns), do: ~H""
end
