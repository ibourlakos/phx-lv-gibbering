defmodule GibberingEngine.Projection do
  @moduledoc """
  Behaviour for map projection strategies (grid ↔ screen coordinate transforms).

  A projection module converts between logical grid coordinates and SVG screen
  coordinates. Implement this behaviour to swap camera angles without touching
  rendering code.
  """

  @doc "Convert grid (x, y) to screen (sx, sy). map_w and map_h are grid dimensions."
  @callback grid_to_screen(
              x :: integer(),
              y :: integer(),
              opts :: %{map_w: non_neg_integer(), map_h: non_neg_integer()}
            ) :: {integer(), integer()}

  @doc "Convert screen (sx, sy) back to the nearest grid (x, y)."
  @callback screen_to_grid(
              sx :: integer(),
              sy :: integer(),
              opts :: %{map_w: non_neg_integer(), map_h: non_neg_integer()}
            ) :: {integer(), integer()}

  @doc "SVG canvas origin point {origin_x, origin_y} for the given map dimensions."
  @callback origin(
              map_w :: non_neg_integer(),
              map_h :: non_neg_integer(),
              opts :: map()
            ) :: {integer(), integer()}
end
