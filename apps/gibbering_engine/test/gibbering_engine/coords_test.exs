defmodule GibberingEngine.CoordsTest do
  use ExUnit.Case, async: true

  alias GibberingEngine.Coords
  alias GibberingEngine.Projection.Isometric

  describe "game_grid/3" do
    test "builds a {x, y, elevation} address" do
      assert Coords.game_grid(3, 4, 1) == {3, 4, 1}
    end

    test "defaults elevation to 0" do
      assert Coords.game_grid(3, 4) == {3, 4, 0}
    end
  end

  describe "iso_project/4" do
    test "elevation 0 matches the existing ground-level projection" do
      opts = %{map_w: 10, map_h: 10}
      assert Coords.iso_project(2, 3, 0, opts) == Isometric.to_screen(2, 3, 10, 10)
    end

    test "raising elevation moves the tile up on screen (lower sy) by tile_h/2 per level" do
      opts = %{map_w: 10, map_h: 10}
      {sx0, sy0} = Coords.iso_project(2, 3, 0, opts)
      {sx1, sy1} = Coords.iso_project(2, 3, 1, opts)

      assert sx1 == sx0
      assert sy1 == sy0 - div(Isometric.tile_h(), 2)
    end

    test "elevation 2 moves up twice as much as elevation 1" do
      opts = %{map_w: 10, map_h: 10}
      {_, sy0} = Coords.iso_project(2, 3, 0, opts)
      {_, sy2} = Coords.iso_project(2, 3, 2, opts)

      assert sy2 == sy0 - 2 * div(Isometric.tile_h(), 2)
    end
  end

  describe "edge_key/3" do
    test "south and east are already canonical" do
      assert Coords.edge_key(3, 4, :south) == {3, 4, :south}
      assert Coords.edge_key(3, 4, :east) == {3, 4, :east}
    end

    test "north normalises to the south edge of the tile above" do
      assert Coords.edge_key(3, 4, :north) == {3, 3, :south}
    end

    test "west normalises to the east edge of the tile to the left" do
      assert Coords.edge_key(3, 4, :west) == {2, 4, :east}
    end

    test "shared wall between two tiles resolves to the same key from either side" do
      # {3,4,:north} is the same physical wall as {3,3,:south}
      assert Coords.edge_key(3, 4, :north) == Coords.edge_key(3, 3, :south)
      # {3,4,:west} is the same physical wall as {2,4,:east}
      assert Coords.edge_key(3, 4, :west) == Coords.edge_key(2, 4, :east)
    end
  end

  describe "decode_edges/1" do
    test "decodes JSONB string keys into canonical edge_key tuples" do
      raw = %{
        "3,4,south" => %{"type" => "wall", "open" => false},
        "5,6,east" => %{"type" => "door", "open" => true}
      }

      assert Coords.decode_edges(raw) == %{
               {3, 4, :south} => %{type: :wall, open: false},
               {5, 6, :east} => %{type: :door, open: true}
             }
    end

    test "empty map decodes to empty map" do
      assert Coords.decode_edges(%{}) == %{}
    end
  end
end
