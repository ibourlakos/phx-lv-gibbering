defmodule GibberingWeb.IsoProjectionTest do
  use ExUnit.Case, async: true

  alias GibberingWeb.IsoProjection

  describe "to_screen/3" do
    test "origin tile (0,0) maps to origin offset" do
      {sx, sy} = IsoProjection.to_screen(0, 0, 10)
      assert sx == IsoProjection.origin_x(10)
      assert sy == IsoProjection.origin_y()
    end

    test "moving along x increases both sx and sy" do
      {sx0, sy0} = IsoProjection.to_screen(0, 0, 10)
      {sx1, sy1} = IsoProjection.to_screen(1, 0, 10)
      assert sx1 > sx0
      assert sy1 > sy0
    end

    test "moving along y decreases sx and increases sy" do
      {sx0, sy0} = IsoProjection.to_screen(0, 0, 10)
      {sx1, sy1} = IsoProjection.to_screen(0, 1, 10)
      assert sx1 < sx0
      assert sy1 > sy0
    end

    test "diagonal (n,n) lands back at same sx as origin" do
      {sx0, _} = IsoProjection.to_screen(0, 0, 10)
      {sx5, _} = IsoProjection.to_screen(5, 5, 10)
      assert sx0 == sx5
    end
  end

  describe "diamond_points/2" do
    test "returns a string with exactly 4 coordinate pairs" do
      points = IsoProjection.diamond_points(100, 50)
      pairs = String.split(points, " ")
      assert length(pairs) == 4
    end

    test "each pair is in 'integer,integer' format" do
      points = IsoProjection.diamond_points(100, 50)

      points
      |> String.split(" ")
      |> Enum.each(fn pair ->
        assert String.match?(pair, ~r/^\d+,\d+$/)
      end)
    end

    test "first pair is the top vertex (sx, sy)" do
      {sx, sy} = {100, 50}
      points = IsoProjection.diamond_points(sx, sy)
      first = points |> String.split(" ") |> hd()
      assert first == "#{sx},#{sy}"
    end
  end

  describe "depth_key/2" do
    test "equals x + y" do
      assert IsoProjection.depth_key(3, 4) == 7
      assert IsoProjection.depth_key(0, 0) == 0
    end

    test "increases as x+y increases" do
      assert IsoProjection.depth_key(0, 0) < IsoProjection.depth_key(1, 0)
      assert IsoProjection.depth_key(0, 0) < IsoProjection.depth_key(0, 1)
      assert IsoProjection.depth_key(2, 3) < IsoProjection.depth_key(4, 4)
    end

    test "equal for same sum regardless of axis" do
      assert IsoProjection.depth_key(2, 3) == IsoProjection.depth_key(3, 2)
    end
  end

  describe "sprite_pos/2" do
    test "sprite is centered horizontally on tile top" do
      {sx, sy} = IsoProjection.to_screen(5, 5, 10)
      {ix, _iy} = IsoProjection.sprite_pos(sx, sy)
      assert ix == sx - div(IsoProjection.tile_w(), 2)
    end

    test "sprite extends upward from tile position" do
      {sx, sy} = IsoProjection.to_screen(5, 5, 10)
      {_ix, iy} = IsoProjection.sprite_pos(sx, sy)
      assert iy < sy
    end
  end

  describe "svg dimensions" do
    test "svg_width grows with both map dimensions" do
      assert IsoProjection.svg_width(5, 5) < IsoProjection.svg_width(10, 10)
    end

    test "svg_height grows with both map dimensions" do
      assert IsoProjection.svg_height(5, 5) < IsoProjection.svg_height(10, 10)
    end

    test "all tiles fit within the svg dimensions for a 10x10 map" do
      map_w = 10
      map_h = 10
      svg_w = IsoProjection.svg_width(map_w, map_h)
      svg_h = IsoProjection.svg_height(map_w, map_h)

      for x <- 0..(map_w - 1), y <- 0..(map_h - 1) do
        {sx, sy} = IsoProjection.to_screen(x, y, map_h)
        {_ix, iy} = IsoProjection.sprite_pos(sx, sy)
        tw2 = div(IsoProjection.tile_w(), 2)

        assert sx - tw2 >= 0, "tile (#{x},#{y}) left tip at #{sx - tw2} < 0"
        assert sx + tw2 <= svg_w, "tile (#{x},#{y}) right tip at #{sx + tw2} > svg_w #{svg_w}"
        assert iy >= 0, "tile (#{x},#{y}) sprite top at #{iy} < 0"

        assert sy + IsoProjection.tile_h() <= svg_h,
               "tile (#{x},#{y}) diamond bottom #{sy + IsoProjection.tile_h()} > svg_h #{svg_h}"
      end
    end
  end
end
