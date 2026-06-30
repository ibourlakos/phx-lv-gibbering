defmodule Gibbering.Engine.AppearanceArchetype do
  @moduledoc false

  # Static sprite-key → archetype mapping. Overridable per-entry via
  # appearance data ("archetype" key in the DB appearances record).
  @sprite_archetypes %{
    "wolf" => :quadruped,
    "bear" => :quadruped,
    "rock" => :structure,
    "chest" => :structure,
    "dead_tree" => :structure
  }

  # Socket offsets (dx, dy) from sprite bottom-centre {32, 64} per archetype + facing.
  # West reuses East sockets (canonical_facing/1 flips the whole group).
  @sockets %{
    biped_upright: %{
      south: %{head: {0, -55}, weapon_hand: {20, -36}, shield_hand: {-20, -36}},
      north: %{head: {0, -55}, weapon_hand: {-20, -36}, shield_hand: {20, -36}},
      east: %{head: {4, -55}, weapon_hand: {20, -36}, shield_hand: {-14, -36}}
    },
    quadruped: %{
      east: %{head: {20, -30}, tail: {-22, -22}},
      south: %{head: {0, -38}}
    },
    swarm: %{south: %{centre: {0, -20}}},
    elemental_amorphous: %{south: %{centre: {0, -20}}},
    structure: %{south: %{centre: {0, -32}}}
  }

  # Layer render order per archetype + facing (back-to-front; last = drawn on top).
  # Demonstrates the shield-ordering rule: shield is in front when south (drawn last),
  # behind when north (drawn first, then body occludes it).
  @layer_order %{
    biped_upright: %{
      south: [:legs, :torso, :shield, :arms, :head],
      north: [:shield, :legs, :torso, :arms, :head],
      east: [:legs, :torso, :arms, :shield, :head]
    },
    quadruped: %{
      east: [:body, :legs, :head],
      south: [:body, :legs, :head]
    },
    swarm: %{south: [:body]},
    elemental_amorphous: %{south: [:body]},
    structure: %{south: [:body]}
  }

  # --- Public API ---

  @doc """
  Resolves archetype atom for a sprite key.
  Appearance data may override the static mapping via an "archetype" string key.
  Falls back to :biped_upright for unknown sprites.
  """
  @spec archetype_for(String.t(), map()) :: atom()
  def archetype_for(sprite_key, appearance_data \\ %{}) do
    case Map.get(appearance_data, "archetype") do
      nil -> Map.get(@sprite_archetypes, sprite_key, :biped_upright)
      a -> String.to_existing_atom(a)
    end
  end

  @doc "Socket offset map for the given archetype (all facings)."
  @spec sockets(atom()) :: map()
  def sockets(archetype), do: Map.get(@sockets, archetype, %{})

  @doc "Layer render order (back-to-front atom list) for the given archetype and facing."
  @spec layer_order(atom(), atom()) :: [atom()]
  def layer_order(archetype, facing) do
    get_in(@layer_order, [archetype, facing]) ||
      get_in(@layer_order, [archetype, :south]) ||
      []
  end

  @doc """
  Returns `{canonical_facing, flip?}`.
  West is rendered as East with a horizontal `scaleX(-1)` flip applied by render_body/2.
  """
  @spec canonical_facing(atom()) :: {atom(), boolean()}
  def canonical_facing(:west), do: {:east, true}
  def canonical_facing(facing), do: {facing, false}

  @doc """
  Renders the body SVG fragment for an entity within a 64×64 local coordinate space.
  The caller is responsible for the `<g transform="translate(ix, iy)">` wrapper.

  All biped-upright entities span ≈62 px vertically — 1.9× the 32 px tile diamond
  height, satisfying the 2–2.5× design constraint.

  Size category scales the sprite proportionally:
    :medium → 1× (no transform)
    :large  → 1.5× (2×2 tile footprint)
    :huge   → 2×   (3×3 tile footprint)
  """
  @spec render_body(map(), map()) :: String.t()
  def render_body(entity, appearances) do
    appearance_data = (appearances || %{})[{"entity", entity.sprite, "default"}] || %{}
    archetype = archetype_for(entity.sprite, appearance_data)
    color = Map.get(appearance_data, "body_color") || default_color(archetype)
    facing = entity[:facing] || :south
    size = entity[:size] || :medium

    {canonical, flip} = canonical_facing(facing)
    svg = archetype |> render_archetype(canonical, color) |> apply_scale(size)

    if flip do
      ~s[<g transform="scale(-1,1) translate(-64,0)">#{svg}</g>]
    else
      svg
    end
  end

  # --- Private helpers ---

  defp default_color(:quadruped), do: "#706050"
  defp default_color(:structure), do: "#787878"
  defp default_color(:swarm), do: "#4a3a2a"
  defp default_color(:elemental_amorphous), do: "#4060c0"
  defp default_color(_), do: "#7f8c8d"

  defp apply_scale(svg, :medium), do: svg

  defp apply_scale(svg, size) do
    s =
      case size do
        :large -> 1.5
        :huge -> 2.0
        _ -> 1.0
      end

    ~s[<g transform="scale(#{s})">#{svg}</g>]
  end

  defp render_archetype(:biped_upright, facing, color), do: render_biped(facing, color)
  defp render_archetype(:quadruped, facing, color), do: render_quadruped(facing, color)
  defp render_archetype(:swarm, _facing, color), do: render_swarm(color)
  defp render_archetype(:elemental_amorphous, _facing, color), do: render_elemental(color)
  defp render_archetype(:structure, _facing, color), do: render_structure(color)

  # ---------------------------------------------------------------------------
  # Biped-upright: visible height ≈ 62 px ≈ 1.94× tile_h (tile_h = 32 px)
  # Layers drawn in @layer_order[:biped_upright][facing] order.
  # ---------------------------------------------------------------------------

  # South: facing viewer. Shield drawn after torso → in front.
  defp render_biped(:south, color) do
    """
    <ellipse cx="32" cy="60" rx="16" ry="5" fill="rgba(0,0,0,0.35)"/>
    <rect x="22" y="42" width="8" height="18" rx="3" fill="#{color}"/>
    <rect x="34" y="42" width="8" height="18" rx="3" fill="#{color}"/>
    <rect x="18" y="20" width="28" height="24" rx="4" fill="#{color}"/>
    <rect x="8" y="23" width="10" height="14" rx="3" fill="#{color}" opacity="0.6"/>
    <ellipse cx="51" cy="28" rx="6" ry="8" fill="#{color}"/>
    <circle cx="32" cy="9" r="9" fill="#c9a87c" stroke="rgba(0,0,0,0.4)" stroke-width="1"/>
    <circle cx="28" cy="9" r="1.5" fill="#333"/>
    <circle cx="36" cy="9" r="1.5" fill="#333"/>
    """
    |> String.trim()
  end

  # North: facing away. Shield drawn before torso → behind body.
  defp render_biped(:north, color) do
    """
    <ellipse cx="32" cy="60" rx="16" ry="5" fill="rgba(0,0,0,0.35)"/>
    <rect x="8" y="23" width="10" height="14" rx="3" fill="#{color}" opacity="0.6"/>
    <rect x="22" y="42" width="8" height="18" rx="3" fill="#{color}" opacity="0.8"/>
    <rect x="34" y="42" width="8" height="18" rx="3" fill="#{color}" opacity="0.8"/>
    <rect x="18" y="20" width="28" height="24" rx="4" fill="#{color}" opacity="0.85"/>
    <ellipse cx="51" cy="28" rx="6" ry="8" fill="#{color}" opacity="0.7"/>
    <circle cx="32" cy="9" r="9" fill="#{color}" opacity="0.9"/>
    """
    |> String.trim()
  end

  # East: side profile. Narrower, shield partially visible to the back side.
  defp render_biped(:east, color) do
    """
    <ellipse cx="36" cy="60" rx="12" ry="5" fill="rgba(0,0,0,0.35)"/>
    <rect x="30" y="42" width="7" height="18" rx="3" fill="#{color}"/>
    <rect x="26" y="20" width="16" height="24" rx="4" fill="#{color}"/>
    <ellipse cx="46" cy="28" rx="5" ry="7" fill="#{color}"/>
    <rect x="20" y="23" width="8" height="12" rx="3" fill="#{color}" opacity="0.6"/>
    <circle cx="36" cy="9" r="9" fill="#c9a87c" stroke="rgba(0,0,0,0.4)" stroke-width="1"/>
    <circle cx="40" cy="9" r="1.5" fill="#333"/>
    """
    |> String.trim()
  end

  # ---------------------------------------------------------------------------
  # Quadruped: horizontal body, 4 legs, head extended on the east axis.
  # West facing = east + scaleX(-1) flip (handled by render_body/2).
  # ---------------------------------------------------------------------------

  # East: head at right (east), tail at left (west).
  defp render_quadruped(:east, color) do
    """
    <ellipse cx="32" cy="58" rx="24" ry="6" fill="rgba(0,0,0,0.4)"/>
    <ellipse cx="28" cy="42" rx="20" ry="13" fill="#{color}"/>
    <ellipse cx="50" cy="34" rx="12" ry="9" fill="#{color}"/>
    <ellipse cx="60" cy="39" rx="6" ry="5" fill="#{color}" opacity="0.85"/>
    <polygon points="46,26 50,17 54,26" fill="#{color}"/>
    <circle cx="54" cy="33" r="2" fill="#111"/>
    <path d="M8,42 Q-2,28 5,35" stroke="#{color}" fill="none" stroke-width="5" stroke-linecap="round"/>
    <rect x="16" y="50" width="6" height="12" rx="3" fill="#{color}" opacity="0.85"/>
    <rect x="26" y="50" width="6" height="12" rx="3" fill="#{color}" opacity="0.85"/>
    <rect x="36" y="50" width="6" height="12" rx="3" fill="#{color}" opacity="0.85"/>
    <rect x="46" y="50" width="6" height="12" rx="3" fill="#{color}" opacity="0.85"/>
    """
    |> String.trim()
  end

  # South: compact view, head forward (toward viewer).
  defp render_quadruped(:south, color) do
    """
    <ellipse cx="32" cy="58" rx="20" ry="6" fill="rgba(0,0,0,0.4)"/>
    <ellipse cx="32" cy="44" rx="14" ry="16" fill="#{color}"/>
    <ellipse cx="32" cy="26" rx="12" ry="10" fill="#{color}"/>
    <ellipse cx="32" cy="33" rx="7" ry="5" fill="#{color}" opacity="0.85"/>
    <polygon points="23,18 21,10 27,18" fill="#{color}"/>
    <polygon points="41,18 43,10 37,18" fill="#{color}"/>
    <circle cx="26" cy="24" r="2" fill="#111"/>
    <circle cx="38" cy="24" r="2" fill="#111"/>
    <rect x="18" y="52" width="6" height="10" rx="3" fill="#{color}" opacity="0.85"/>
    <rect x="25" y="52" width="6" height="10" rx="3" fill="#{color}" opacity="0.85"/>
    <rect x="38" y="52" width="6" height="10" rx="3" fill="#{color}" opacity="0.85"/>
    <rect x="45" y="52" width="6" height="10" rx="3" fill="#{color}" opacity="0.85"/>
    """
    |> String.trim()
  end

  # North: back view, tail stub visible.
  defp render_quadruped(:north, color) do
    """
    <ellipse cx="32" cy="58" rx="20" ry="6" fill="rgba(0,0,0,0.4)"/>
    <ellipse cx="32" cy="44" rx="14" ry="16" fill="#{color}" opacity="0.85"/>
    <ellipse cx="32" cy="26" rx="12" ry="10" fill="#{color}" opacity="0.85"/>
    <polygon points="23,18 21,10 27,18" fill="#{color}"/>
    <polygon points="41,18 43,10 37,18" fill="#{color}"/>
    <path d="M32,12 Q28,4 32,2" stroke="#{color}" fill="none" stroke-width="4" stroke-linecap="round"/>
    <rect x="18" y="52" width="6" height="10" rx="3" fill="#{color}" opacity="0.85"/>
    <rect x="25" y="52" width="6" height="10" rx="3" fill="#{color}" opacity="0.85"/>
    <rect x="38" y="52" width="6" height="10" rx="3" fill="#{color}" opacity="0.85"/>
    <rect x="45" y="52" width="6" height="10" rx="3" fill="#{color}" opacity="0.85"/>
    """
    |> String.trim()
  end

  # ---------------------------------------------------------------------------
  # Swarm: cluster of dots; no distinct facing.
  # ---------------------------------------------------------------------------

  defp render_swarm(color) do
    """
    <ellipse cx="32" cy="58" rx="22" ry="5" fill="rgba(0,0,0,0.35)"/>
    <circle cx="18" cy="48" r="7" fill="#{color}" opacity="0.75"/>
    <circle cx="32" cy="44" r="6" fill="#{color}" opacity="0.85"/>
    <circle cx="46" cy="48" r="7" fill="#{color}" opacity="0.75"/>
    <circle cx="24" cy="54" r="5" fill="#{color}" opacity="0.65"/>
    <circle cx="40" cy="54" r="5" fill="#{color}" opacity="0.65"/>
    <circle cx="32" cy="52" r="4" fill="#{color}" opacity="0.7"/>
    """
    |> String.trim()
  end

  # ---------------------------------------------------------------------------
  # Elemental/amorphous: blob with no discrete anatomy.
  # ---------------------------------------------------------------------------

  defp render_elemental(color) do
    """
    <ellipse cx="32" cy="58" rx="20" ry="5" fill="rgba(0,0,0,0.3)"/>
    <ellipse cx="32" cy="44" rx="22" ry="18" fill="#{color}" opacity="0.85"/>
    <ellipse cx="32" cy="30" rx="14" ry="12" fill="#{color}" opacity="0.7"/>
    <ellipse cx="22" cy="40" rx="8" ry="6" fill="#{color}" opacity="0.5"/>
    <ellipse cx="42" cy="40" rx="8" ry="6" fill="#{color}" opacity="0.5"/>
    """
    |> String.trim()
  end

  # ---------------------------------------------------------------------------
  # Structure: static block, no facing.
  # ---------------------------------------------------------------------------

  defp render_structure(color) do
    """
    <ellipse cx="32" cy="60" rx="22" ry="6" fill="rgba(0,0,0,0.4)"/>
    <rect x="14" y="30" width="36" height="28" rx="4" fill="#{color}"/>
    <ellipse cx="32" cy="30" rx="18" ry="7" fill="#{color}"/>
    <ellipse cx="32" cy="30" rx="18" ry="7" fill="rgba(255,255,255,0.15)"/>
    """
    |> String.trim()
  end
end
