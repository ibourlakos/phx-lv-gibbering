defmodule Gibbering.Engine.SpriteCompositor do
  @moduledoc false

  # Compositing pipeline for entity SVG fragments.
  #
  # Design decisions (see issue #100):
  #   - Compositing is server-side: Elixir emits SVG strings; LiveView diffs handle redundancy.
  #   - Layer order is declarative; compose/3 is a pure function of (entity, appearances, opts).
  #   - The caller wraps the result in <g transform="translate(sx, sy)"> for positioning.
  #   - Anchor offsets (anchor_x, anchor_y) are style-specific and live in appearance data.
  #   - No explicit fragment cache: LiveView diffing is the primary deduplication mechanism.
  #     An ETS cache is deferred until profiling demonstrates it is needed (see #104).

  @layer_order [:body, :selection_ring, :hp_bar]

  @doc """
  Composes an SVG fragment for `entity` using `appearances` and optional render opts.

  Returns a raw SVG string. The caller positions via `<g transform="translate(sx, sy)">`.

  Options:
    - `:selected`   (boolean, default false) — render selection ring
    - `:show_hp`    (boolean, default true)  — render HP bar
    - `:show_body`  (boolean, default true)  — render the body fallback rect; set false
                     when a named entity_sprite component handles the body geometry
  """
  def compose(entity, appearances, opts \\ []) do
    selected = Keyword.get(opts, :selected, false)
    show_hp = Keyword.get(opts, :show_hp, true)
    show_body = Keyword.get(opts, :show_body, true)

    @layer_order
    |> Enum.flat_map(
      &build_layer(&1, entity, appearances,
        selected: selected,
        show_hp: show_hp,
        show_body: show_body
      )
    )
    |> Enum.join("\n")
  end

  @doc "Ordered list of layers this compositor renders, in bottom-to-top draw order."
  def layer_order, do: @layer_order

  # ---------------------------------------------------------------------------
  # Layer builders — each returns a list of SVG string fragments ([] = skip)
  # ---------------------------------------------------------------------------

  defp build_layer(:body, entity, appearances, opts) do
    if Keyword.get(opts, :show_body, true) do
      data = appearances[{"entity", entity.sprite, "default"}] || %{}
      color = data["body_color"] || "#7f8c8d"
      ax = data["anchor_x"] || 0
      ay = data["anchor_y"] || 0
      [~s(<rect x="#{ax}" y="#{ay}" width="32" height="32" rx="4" fill="#{color}" />)]
    else
      []
    end
  end

  defp build_layer(:selection_ring, _entity, _appearances, opts) do
    if Keyword.get(opts, :selected) do
      [
        ~s(<ellipse cx="16" cy="46" rx="20" ry="8" fill="none" stroke="#f0e040" stroke-width="2" opacity="0.85" />)
      ]
    else
      []
    end
  end

  defp build_layer(:hp_bar, entity, _appearances, opts) do
    max_hp = Map.get(entity, :max_hp) || 0

    if Keyword.get(opts, :show_hp) && max_hp > 0 do
      frac = (entity.hp / max_hp) |> max(0.0) |> min(1.0)
      # 56px wide bar at x=4, y=-9 (above the sprite box top edge), matching
      # the tile_w - 8 layout used in the GameLive template.
      bar_w = round(56 * frac)

      [
        ~s(<rect x="4" y="-9" width="56" height="5" rx="2" fill="#1f2937" />),
        ~s(<rect x="4" y="-9" width="#{bar_w}" height="5" rx="2" fill="#{hp_color(frac)}" />)
      ]
    else
      []
    end
  end

  defp hp_color(f) when f > 0.5, do: "#2ecc71"
  defp hp_color(f) when f > 0.25, do: "#f39c12"
  defp hp_color(_), do: "#e74c3c"
end
