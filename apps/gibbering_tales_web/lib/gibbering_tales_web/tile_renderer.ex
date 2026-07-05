defmodule GibberingTalesWeb.TileRenderer do
  @moduledoc false

  # Pure SVG tile rendering — no LiveView, no OTP, no DB.
  # The caller computes screen-space diamond points via IsoProjection and passes
  # them as a string so this module has no projection dependency.

  @doc """
  Returns an SVG `<polygon>` string for a ground tile.

  `points` is a pre-computed SVG points string from `IsoProjection.diamond_points/2`.
  `appearances` is the Catalogue.Cache lookup map keyed by `{content_type, key, state}`.
  """
  @spec render_tile(map(), non_neg_integer(), non_neg_integer(), String.t(), map()) :: String.t()
  def render_tile(tile, x, y, points, appearances) do
    texture = Map.get(tile, :texture, "grass")
    fill = tile_fill(appearances, texture)
    stroke = tile_stroke(appearances, texture)

    """
    <polygon
      points="#{points}"
      fill="#{fill}"
      stroke="#{stroke}"
      stroke-width="1"
      phx-click="inspect_tile"
      phx-value-x="#{x}"
      phx-value-y="#{y}"
      data-grid-x="#{x}"
      data-grid-y="#{y}"
      data-tile-texture="#{texture}"
      style="cursor: crosshair;"
    />
    """
  end

  @doc "Returns the fill colour for a tile texture from the appearances catalogue."
  @spec tile_fill(map(), String.t()) :: String.t()
  def tile_fill(appearances, texture) do
    (appearances[{"tile", texture, "default"}] || %{})["fill"] || "#7f8c8d"
  end

  @doc "Returns the stroke colour for a tile texture from the appearances catalogue."
  @spec tile_stroke(map(), String.t()) :: String.t()
  def tile_stroke(appearances, texture) do
    (appearances[{"tile", texture, "default"}] || %{})["stroke"] || "#5d6d7e"
  end
end
