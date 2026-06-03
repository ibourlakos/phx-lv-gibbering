defmodule GibberingWeb.IsoProjection do
  @moduledoc false

  # 2:1 dimetric isometric projection constants.
  # tile_h == tile_w / 2 is the 2:1 ratio that gives the DST camera angle.
  @tile_w 64
  @tile_h 32
  @sprite_h 64
  # origin_y provides top padding so sprites on row 0 don't clip the SVG edge.
  @origin_y 64

  def tile_w, do: @tile_w
  def tile_h, do: @tile_h
  def sprite_h, do: @sprite_h
  def origin_y, do: @origin_y

  # Horizontal origin: shifts the grid right so the leftmost column (y=map_h-1) starts at ~tile_w/2.
  def origin_x(map_h), do: map_h * div(@tile_w, 2) + div(@tile_w, 2)

  # Total SVG canvas dimensions for a given map size.
  def svg_width(map_w, map_h), do: (map_w + map_h) * div(@tile_w, 2) + @tile_w

  def svg_height(map_w, map_h),
    do: (map_w + map_h) * div(@tile_h, 2) + @origin_y + @sprite_h + @tile_h

  # Grid (x, y) → screen (sx, sy).  sx/sy is the *top vertex* of the diamond tile.
  def to_screen(x, y, map_h) do
    sx = (x - y) * div(@tile_w, 2) + origin_x(map_h)
    sy = (x + y) * div(@tile_h, 2) + @origin_y
    {sx, sy}
  end

  # SVG polygon points string for a diamond centered on (sx, sy as top vertex).
  def diamond_points(sx, sy) do
    tw2 = div(@tile_w, 2)
    th2 = div(@tile_h, 2)
    "#{sx},#{sy} #{sx + tw2},#{sy + th2} #{sx},#{sy + @tile_h} #{sx - tw2},#{sy + th2}"
  end

  # Top-left corner of the 64×64 sprite box.
  # Shadow/feet sit at local y≈60, which aligns with the tile diamond bottom center (sy + tile_h).
  def sprite_pos(sx, sy), do: {sx - div(@tile_w, 2), sy - @sprite_h + 32}

  # Painter's algorithm key: ascending x+y means drawn first (behind).
  def depth_key(x, y), do: x + y
end
