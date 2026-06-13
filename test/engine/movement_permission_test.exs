defmodule Gibbering.Engine.MovementPermissionTest do
  use ExUnit.Case, async: true

  import Gibbering.GameFixtures
  alias Gibbering.Engine.Rules

  # ---------------------------------------------------------------------------
  # tile_movement_permission/3
  # ---------------------------------------------------------------------------

  describe "tile_movement_permission/3" do
    test "returns tile walk value when no entities occupy the tile" do
      state = build_state()
      assert Rules.tile_movement_permission(state, 0, 0, "walk") == 100
    end

    test "returns 0 for a tile whose movement map lacks the requested mode" do
      state = build_state() |> with_tile({1, 1}, movement: %{"swim" => 100})
      assert Rules.tile_movement_permission(state, 1, 1, "walk") == 0
    end

    test "returns 0 for a tile absent from grid_tiles" do
      state = %{build_state() | grid_tiles: Map.delete(build_state().grid_tiles, {2, 2})}
      assert Rules.tile_movement_permission(state, 2, 2, "walk") == 0
    end

    test "returns 0 for a fully blocked tile (movement empty map)" do
      state = build_state() |> with_tile({1, 0}, movement: %{})
      assert Rules.tile_movement_permission(state, 1, 0, "walk") == 0
    end

    test "returns the tile value when no entity at that coord has stats[\"movement\"]" do
      # The monster at (3,3) has no stats["movement"] key — should not constrain
      state = build_state()
      assert Rules.tile_movement_permission(state, 3, 3, "walk") == 100
    end

    test "entity with stats[\"movement\"][mode] constrains via min(tile, entity)" do
      state =
        build_state()
        |> with_entity(monster_id(), x: 1, y: 1, stats: %{"movement" => %{"walk" => 50}})

      assert Rules.tile_movement_permission(state, 1, 1, "walk") == 50
    end

    test "entity with stats[\"movement\"] but missing the mode key blocks movement (absent = 0)" do
      state =
        build_state()
        |> with_entity(monster_id(), x: 1, y: 1, stats: %{"movement" => %{"swim" => 100}})

      assert Rules.tile_movement_permission(state, 1, 1, "walk") == 0
    end

    test "entity without stats[\"movement\"] key does not constrain tile permission" do
      state =
        build_state()
        |> with_entity(monster_id(), x: 1, y: 1, stats: %{"speed" => 30})

      assert Rules.tile_movement_permission(state, 1, 1, "walk") == 100
    end

    test "tile value is the binding constraint when lower than entity" do
      state =
        build_state()
        |> with_tile({1, 1}, movement: %{"walk" => 30})
        |> with_entity(monster_id(), x: 1, y: 1, stats: %{"movement" => %{"walk" => 80}})

      assert Rules.tile_movement_permission(state, 1, 1, "walk") == 30
    end

    test "entity value is the binding constraint when lower than tile" do
      state =
        build_state()
        |> with_tile({1, 1}, movement: %{"walk" => 80})
        |> with_entity(monster_id(), x: 1, y: 1, stats: %{"movement" => %{"walk" => 20}})

      assert Rules.tile_movement_permission(state, 1, 1, "walk") == 20
    end

    test "works for climb mode" do
      state = build_state() |> with_tile({0, 0}, movement: %{"walk" => 100, "climb" => 50})
      assert Rules.tile_movement_permission(state, 0, 0, "climb") == 50
    end

    test "works for swim mode" do
      state = build_state() |> with_tile({0, 0}, movement: %{"walk" => 100, "swim" => 60})
      assert Rules.tile_movement_permission(state, 0, 0, "swim") == 60
    end

    test "works for fly mode" do
      state = build_state() |> with_tile({0, 0}, movement: %{"walk" => 100, "fly" => 100})
      assert Rules.tile_movement_permission(state, 0, 0, "fly") == 100
    end
  end

  # ---------------------------------------------------------------------------
  # valid_moves/2 — movement permission integration
  # ---------------------------------------------------------------------------

  describe "valid_moves/2 movement permission integration" do
    test "excludes tiles where walk permission is 0 (empty movement map)" do
      state = build_state() |> with_tile({2, 1}, movement: %{})
      moves = Rules.valid_moves(state, hero_id())
      refute {2, 1} in moves
    end

    test "includes tiles where walk permission > 0" do
      state = build_state() |> with_tile({2, 1}, movement: %{"walk" => 50})
      moves = Rules.valid_moves(state, hero_id())
      assert {2, 1} in moves
    end

    test "rubble tile after destructible entity death is walk-passable" do
      state = build_state() |> with_entity(monster_id(), hp: 1, tags: ["destructible"])
      monster_pos = {state.entities[monster_id()].x, state.entities[monster_id()].y}
      {_result, new_state, _details} = Rules.attack(state, hero_id(), monster_id(), roll: 20)

      assert Rules.tile_movement_permission(
               new_state,
               elem(monster_pos, 0),
               elem(monster_pos, 1),
               "walk"
             ) == 100
    end
  end
end
