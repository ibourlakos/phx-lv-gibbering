defmodule GibberingWeb.TileRendererTest do
  # Layer 1 — pure function tests; no LiveView, no DB, no OTP process.
  use ExUnit.Case, async: true

  alias GibberingWeb.TileRenderer

  @grass_tile %{texture: "grass"}
  @stone_tile %{texture: "stone"}
  @points "0,0 32,16 0,32 -32,16"

  @grass_appearances %{
    {"tile", "grass", "default"} => %{"fill" => "#5a7a3a", "stroke" => "#4a6a2a"}
  }

  describe "render_tile/5" do
    test "includes data-grid-x and data-grid-y for the given coordinates" do
      svg = TileRenderer.render_tile(@grass_tile, 3, 7, @points, %{})
      assert svg =~ ~s(data-grid-x="3")
      assert svg =~ ~s(data-grid-y="7")
    end

    test "includes data-tile-texture matching the tile texture" do
      svg = TileRenderer.render_tile(@grass_tile, 0, 0, @points, %{})
      assert svg =~ ~s(data-tile-texture="grass")

      svg2 = TileRenderer.render_tile(@stone_tile, 0, 0, @points, %{})
      assert svg2 =~ ~s(data-tile-texture="stone")
    end

    test "includes phx-value-x and phx-value-y for LiveView click handling" do
      svg = TileRenderer.render_tile(@grass_tile, 2, 4, @points, %{})
      assert svg =~ ~s(phx-value-x="2")
      assert svg =~ ~s(phx-value-y="4")
    end

    test "uses appearance fill colour when present in catalogue" do
      svg = TileRenderer.render_tile(@grass_tile, 0, 0, @points, @grass_appearances)
      assert svg =~ ~s(fill="#5a7a3a")
    end

    test "falls back to default fill when texture not in appearances" do
      svg = TileRenderer.render_tile(@grass_tile, 0, 0, @points, %{})
      assert svg =~ ~s(fill="#7f8c8d")
    end

    test "uses appearance stroke colour when present in catalogue" do
      svg = TileRenderer.render_tile(@grass_tile, 0, 0, @points, @grass_appearances)
      assert svg =~ ~s(stroke="#4a6a2a")
    end

    test "uses the supplied points string verbatim" do
      custom_points = "1,2 3,4 5,6 7,8"
      svg = TileRenderer.render_tile(@grass_tile, 0, 0, custom_points, %{})
      assert svg =~ ~s(points="#{custom_points}")
    end
  end

  describe "tile_fill/2" do
    test "returns fill from appearances when present" do
      assert TileRenderer.tile_fill(@grass_appearances, "grass") == "#5a7a3a"
    end

    test "returns default fill when texture absent" do
      assert TileRenderer.tile_fill(%{}, "unknown") == "#7f8c8d"
    end
  end

  describe "tile_stroke/2" do
    test "returns stroke from appearances when present" do
      assert TileRenderer.tile_stroke(@grass_appearances, "grass") == "#4a6a2a"
    end

    test "returns default stroke when texture absent" do
      assert TileRenderer.tile_stroke(%{}, "unknown") == "#5d6d7e"
    end
  end
end
