defmodule GibberingEngine.Coords do
  @moduledoc """
  Canonical coordinate model for the engine — three spaces:

    1. Game grid `{x, y, elevation}` — the address for all game logic.
    2. SVG render space `{screen_x, screen_y}` — derived via `iso_project/4`, never stored.
    3. Edge addresses `{x, y, direction}` — walls/doors between tiles, normalised via `edge_key/3`.
  """

  alias GibberingEngine.Projection.Isometric

  @type direction :: :north | :south | :east | :west
  @type game_grid :: {integer(), integer(), integer()}
  @type edge_key :: {integer(), integer(), :south | :east}

  @doc "Builds a canonical `{x, y, elevation}` game-grid address. Elevation defaults to 0 (ground)."
  @spec game_grid(integer(), integer(), integer()) :: game_grid()
  def game_grid(x, y, elevation \\ 0), do: {x, y, elevation}

  @doc """
  Projects a game-grid coordinate to SVG screen space.

  Delegates the ground-plane math to `GibberingEngine.Projection.Isometric.to_screen/4`,
  then offsets `screen_y` upward by `tile_h / 2` per elevation level.
  """
  @spec iso_project(integer(), integer(), integer(), %{map_w: non_neg_integer(), map_h: non_neg_integer()}) ::
          {integer(), integer()}
  def iso_project(x, y, elevation, %{map_w: map_w, map_h: map_h}) do
    {sx, sy} = Isometric.to_screen(x, y, map_w, map_h)
    {sx, sy - elevation * div(Isometric.tile_h(), 2)}
  end

  @doc """
  Normalises an edge address so each wall/door has exactly one canonical key.

  `{x, y, :north}` is the same edge as `{x, y - 1, :south}`; `{x, y, :west}` is the same
  edge as `{x - 1, y, :east}`. Canonical form always uses `:south` or `:east`.
  """
  @spec edge_key(integer(), integer(), direction()) :: edge_key()
  def edge_key(x, y, :north), do: {x, y - 1, :south}
  def edge_key(x, y, :south), do: {x, y, :south}
  def edge_key(x, y, :west), do: {x - 1, y, :east}
  def edge_key(x, y, :east), do: {x, y, :east}

  @doc """
  Decodes a `maps.edges` JSONB value (string keys, e.g. `"3,4,south"`) into the canonical
  `%{edge_key() => %{type: :wall | :door, open: boolean()}}` runtime shape.
  """
  @spec decode_edges(map()) :: %{edge_key() => %{type: :wall | :door, open: boolean()}}
  def decode_edges(edges) when is_map(edges) do
    Map.new(edges, fn {key, value} -> {decode_edge_key(key), decode_edge_value(value)} end)
  end

  defp decode_edge_key(key) do
    [x, y, dir] = String.split(key, ",")
    direction = if dir == "south", do: :south, else: :east
    {String.to_integer(x), String.to_integer(y), direction}
  end

  defp decode_edge_value(%{"type" => type, "open" => open}) do
    edge_type = if type == "wall", do: :wall, else: :door
    %{type: edge_type, open: open}
  end
end
