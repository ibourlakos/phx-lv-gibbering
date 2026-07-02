defmodule GibberingEngine.SpriteCompositor do
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

  @layer_order [:body, :selection_ring, :hp_bar, :condition_badges]

  @doc """
  Composes an SVG fragment for `entity` using `appearances` and optional render opts.

  Returns a raw SVG string. The caller positions via `<g transform="translate(sx, sy)">`.

  Options:
    - `:selected`        (boolean, default false)   — render selection ring
    - `:show_hp`         (boolean, default true)    — render HP bar
    - `:show_body`       (boolean, default true)    — render the body fallback rect; set false
                          when a named entity_sprite component handles the body geometry
    - `:viewer_role`     (`:dm | :player`, default `:player`) — controls HP bar data attributes:
                          `:dm` embeds exact `data-hp` / `data-max-hp`; `:player` embeds
                          `data-hp-bucket` with a label (Unscathed / Hurt / Bloodied / Critical)
    - `:badge_renderer`  (`(entity -> String.t())`, default `fn _ -> "" end`) — called to render
                          condition badges; inject `GibberingTales.ConditionBadge.render_badges/1`
                          when running inside the tales app
  """
  def compose(entity, appearances, opts \\ []) do
    selected = Keyword.get(opts, :selected, false)
    show_hp = Keyword.get(opts, :show_hp, true)
    show_body = Keyword.get(opts, :show_body, true)
    viewer_role = Keyword.get(opts, :viewer_role, :player)
    badge_renderer = Keyword.get(opts, :badge_renderer, fn _ -> "" end)

    @layer_order
    |> Enum.flat_map(
      &build_layer(&1, entity, appearances,
        selected: selected,
        show_hp: show_hp,
        show_body: show_body,
        viewer_role: viewer_role,
        badge_renderer: badge_renderer
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

      [
        ~s(<rect x="#{ax}" y="#{ay}" width="32" height="32" rx="4" fill="#{color}" data-layer="body" />)
      ]
    else
      []
    end
  end

  defp build_layer(:selection_ring, _entity, _appearances, opts) do
    if Keyword.get(opts, :selected) do
      [
        ~s(<ellipse cx="16" cy="46" rx="20" ry="8" fill="none" stroke="#f0e040" stroke-width="2" opacity="0.85" data-layer="selection-ring" />)
      ]
    else
      []
    end
  end

  defp build_layer(:hp_bar, entity, _appearances, opts) do
    max_hp = Map.get(entity, :max_hp) || 0

    if Keyword.get(opts, :show_hp) && max_hp > 0 do
      hp = entity.hp
      frac = (hp / max_hp) |> max(0.0) |> min(1.0)
      # 56px wide bar at x=4, y=-9 (above the sprite box top edge), matching
      # the tile_w - 8 layout used in the GameLive template.
      bar_w = round(56 * frac)

      role_attr =
        case Keyword.get(opts, :viewer_role, :player) do
          :dm -> ~s(data-hp="#{hp}" data-max-hp="#{max_hp}")
          _ -> ~s(data-hp-bucket="#{bucket_label(frac)}")
        end

      [
        ~s(<g data-layer="hp-bar" #{role_attr}>),
        ~s(<rect x="4" y="-9" width="56" height="5" rx="2" fill="#1f2937" />),
        ~s(<rect x="4" y="-9" width="#{bar_w}" height="5" rx="2" fill="#{hp_color(frac)}" />),
        ~s(</g>)
      ]
    else
      []
    end
  end

  defp build_layer(:condition_badges, entity, _appearances, opts) do
    badge_renderer = Keyword.get(opts, :badge_renderer, fn _ -> "" end)

    case badge_renderer.(entity) do
      "" -> []
      svg -> [~s(<g data-layer="condition-badges">#{svg}</g>)]
    end
  end

  defp hp_color(f) when f > 0.5, do: "#2ecc71"
  defp hp_color(f) when f > 0.25, do: "#f39c12"
  defp hp_color(_), do: "#e74c3c"

  defp bucket_label(f) when f > 0.75, do: "Unscathed"
  defp bucket_label(f) when f > 0.5, do: "Hurt"
  defp bucket_label(f) when f > 0.25, do: "Bloodied"
  defp bucket_label(_), do: "Critical"
end
