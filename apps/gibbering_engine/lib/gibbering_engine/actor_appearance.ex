defmodule GibberingEngine.ActorAppearance do
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

  # Static sprite-key → silhouette mapping, for biped_upright entities only.
  # Overridable per-entry via appearance data ("silhouette" key). Anything not
  # listed here (all PC races, guard, bandit, cultist, ...) renders as :humanoid.
  @sprite_silhouettes %{
    "goblin" => :goblinoid,
    "kobold" => :goblinoid,
    "orc" => :goblinoid,
    "bugbear" => :goblinoid,
    "skeleton" => :undead_gaunt,
    "zombie" => :undead_gaunt,
    "ogre" => :giant,
    "troll" => :giant
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
  # :shadow is always first. Demonstrates the shield-ordering rule: shield is in
  # front when south (drawn last), behind when north (drawn first, then body occludes it).
  @layer_order %{
    biped_upright: %{
      south: [:shadow, :legs, :torso, :shield, :arms, :head],
      north: [:shadow, :shield, :legs, :torso, :arms, :head],
      east: [:shadow, :legs, :torso, :arms, :shield, :head]
    },
    quadruped: %{
      east: [:shadow, :body, :legs, :head],
      south: [:shadow, :body, :legs, :head],
      north: [:shadow, :body, :legs, :head]
    },
    swarm: %{south: [:shadow, :body]},
    elemental_amorphous: %{south: [:shadow, :body]},
    structure: %{south: [:shadow, :body]}
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

  @doc """
  Resolves the silhouette atom for a sprite key within the :biped_upright archetype.
  Appearance data may override the static mapping via a "silhouette" string key.
  Falls back to :humanoid. Non-biped_upright archetypes always resolve to :default —
  they have no silhouette variants.
  """
  @spec silhouette_for(String.t(), atom(), map()) :: atom()
  def silhouette_for(_sprite_key, archetype, _appearance_data) when archetype != :biped_upright,
    do: :default

  def silhouette_for(sprite_key, :biped_upright, appearance_data) do
    case Map.get(appearance_data, "silhouette") do
      nil -> Map.get(@sprite_silhouettes, sprite_key, :humanoid)
      s -> String.to_existing_atom(s)
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
  West is rendered as East with a horizontal `scaleX(-1)` flip applied by render_body/4.
  """
  @spec canonical_facing(atom()) :: {atom(), boolean()}
  def canonical_facing(:west), do: {:east, true}
  def canonical_facing(facing), do: {facing, false}

  @doc """
  Renders the body SVG fragment for an entity within a 64×64 local coordinate space.
  The caller is responsible for the `<g transform="translate(ix, iy)">` wrapper.

  This module is deliberately content-agnostic — it resolves archetype/silhouette/facing/
  layer order and composes the result, but knows nothing about templates or SVG files.
  `render_layer_fun` is injected by the caller: a 6-arity function
  `(style_slug, archetype, silhouette, facing, layer, assigns) -> String.t()` that supplies
  the actual per-layer markup (game-specific content lives with the caller, e.g.
  `GibberingTales.Catalogue.TemplateStore.render/6`).

  All biped-upright entities span ≈62 px vertically — 1.9× the 32 px tile diamond
  height, satisfying the 2–2.5× design constraint.

  Size category scales the sprite proportionally:
    :medium → 1× (no transform)
    :large  → 1.5× (2×2 tile footprint)
    :huge   → 2×   (3×3 tile footprint)
  """
  @spec render_body(map(), map(), String.t(), (String.t(), atom(), atom(), atom(), atom(), map() ->
                                                  String.t())) :: String.t()
  def render_body(entity, appearances, style_slug, render_layer_fun) do
    appearance_data = (appearances || %{})[{"entity", entity.sprite, "default"}] || %{}
    archetype = archetype_for(entity.sprite, appearance_data)
    silhouette = silhouette_for(entity.sprite, archetype, appearance_data)
    color = Map.get(appearance_data, "body_color") || default_color(archetype)
    facing = entity[:facing] || :south
    size = entity[:size] || :medium

    {canonical, flip} = canonical_facing(facing)
    assigns = %{color: color}

    svg =
      archetype
      |> layer_order(canonical)
      |> Enum.map_join(fn layer ->
        render_layer_fun.(style_slug, archetype, silhouette, canonical, layer, assigns)
      end)
      |> apply_scale(size)

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
end
