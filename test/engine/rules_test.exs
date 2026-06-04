defmodule Gibbering.Engine.RulesTest do
  # Pure functions only — no DB, no process. Safe to run async.
  use ExUnit.Case, async: true

  import Gibbering.GameFixtures
  alias Gibbering.Engine.Rules

  # ---------------------------------------------------------------------------
  # valid_moves/2
  # ---------------------------------------------------------------------------

  describe "valid_moves/2" do
    test "returns tiles within movement range" do
      state = build_state()
      # Hero at (2,2) with speed 30 → max 6 tiles. Chebyshev range = octagonal.
      moves = Rules.valid_moves(state, hero_id())
      assert {0, 2} in moves
      assert {4, 2} in moves
      assert {2, 0} in moves
      assert {2, 4} in moves
    end

    test "never includes the entity's current position" do
      state = build_state()
      moves = Rules.valid_moves(state, hero_id())
      refute {2, 2} in moves
    end

    test "respects chebyshev distance cap" do
      # Hero speed 30 → 6 tiles. Place hero at (0,0) on a big map.
      state =
        build_state(map_width: 15, map_height: 15)
        |> with_entity(hero_id(), x: 0, y: 0)

      moves = Rules.valid_moves(state, hero_id())

      # Every returned tile must be within Chebyshev distance 6.
      assert Enum.all?(moves, fn {x, y} -> max(abs(x), abs(y)) <= 6 end)
      # (7, 0) is Chebyshev distance 7 — not reachable.
      refute {7, 0} in moves
      # (6, 6) is Chebyshev distance 6 — reachable (diagonal costs same as orthogonal in 5e).
      assert {6, 6} in moves
    end

    test "excludes unwalkable tiles" do
      state = build_state() |> with_tile({2, 1}, walkable: false)
      moves = Rules.valid_moves(state, hero_id())
      refute {2, 1} in moves
    end

    test "excludes tiles occupied by another hero" do
      # Add a second hero at (2, 1).
      second_hero = %{
        name: "Paladin",
        type: "hero",
        sprite: "paladin.png",
        x: 2,
        y: 1,
        hp: 10,
        max_hp: 10,
        tags: [],
        stats: %{"speed" => 30}
      }

      state = %{build_state() | entities: Map.put(build_state().entities, 99, second_hero)}
      moves = Rules.valid_moves(state, hero_id())
      refute {2, 1} in moves
    end

    test "does not exclude tiles occupied by a monster" do
      # Monsters block attacks, not movement tiles (you can move to their square
      # only if they are gone; but valid_moves does not filter monster squares).
      state = build_state()
      moves = Rules.valid_moves(state, hero_id())
      # Monster is at (3,3) — should still appear in the move list.
      assert {3, 3} in moves
    end
  end

  # ---------------------------------------------------------------------------
  # valid_targets/2
  # ---------------------------------------------------------------------------

  describe "valid_targets/2" do
    test "returns empty list when no enemies are adjacent" do
      # Monster at (4,4), hero at (2,2) — Chebyshev distance 2, not adjacent.
      state = build_state() |> with_entity(monster_id(), x: 4, y: 4)
      assert Rules.valid_targets(state, hero_id()) == []
    end

    test "returns monster id when monster is adjacent orthogonally" do
      state = build_state() |> with_entity(monster_id(), x: 2, y: 3)
      targets = Rules.valid_targets(state, hero_id())
      assert monster_id() in targets
    end

    test "returns monster id when monster is adjacent diagonally (5e melee includes diagonals)" do
      state = build_state() |> with_entity(monster_id(), x: 3, y: 3)
      targets = Rules.valid_targets(state, hero_id())
      assert monster_id() in targets
    end

    test "returns destructible object when adjacent" do
      barrel = %{
        name: "Barrel",
        type: "object",
        sprite: "barrel.png",
        x: 2,
        y: 3,
        hp: 2,
        max_hp: 2,
        tags: ["destructible"],
        stats: %{}
      }

      state = %{build_state() | entities: Map.put(build_state().entities, 50, barrel)}
      targets = Rules.valid_targets(state, hero_id())
      assert 50 in targets
    end

    test "does not return other heroes as targets" do
      ally = %{
        name: "Rogue",
        type: "hero",
        sprite: "rogue.png",
        x: 2,
        y: 3,
        hp: 8,
        max_hp: 8,
        tags: [],
        stats: %{}
      }

      state = %{build_state() | entities: Map.put(build_state().entities, 77, ally)}
      targets = Rules.valid_targets(state, hero_id())
      refute 77 in targets
    end
  end

  # ---------------------------------------------------------------------------
  # attack/3
  # ---------------------------------------------------------------------------

  describe "attack/3" do
    test "reduces target hp by at least 1" do
      state = build_state()
      updated = Rules.attack(state, hero_id(), monster_id())
      original_hp = state.entities[monster_id()].hp
      new_hp = get_in(updated.entities, [monster_id(), :hp]) || 0
      assert new_hp < original_hp
    end

    test "hp cannot drop below 0" do
      state = build_state() |> with_entity(monster_id(), hp: 1)
      updated = Rules.attack(state, hero_id(), monster_id())
      # Either gone or hp == 0; never negative.
      hp = get_in(updated.entities, [monster_id(), :hp])
      assert hp == nil or hp >= 0
    end

    test "removes entity from state when hp reaches 0" do
      state = build_state() |> with_entity(monster_id(), hp: 1)
      updated = Rules.attack(state, hero_id(), monster_id())
      refute Map.has_key?(updated.entities, monster_id())
    end

    test "converts destructible entity tile to rubble on death" do
      state =
        build_state()
        |> with_entity(monster_id(), hp: 1, tags: ["destructible"])

      monster_pos = {state.entities[monster_id()].x, state.entities[monster_id()].y}
      updated = Rules.attack(state, hero_id(), monster_id())

      assert updated.grid_tiles[monster_pos].texture == "rubble"
      assert updated.grid_tiles[monster_pos].walkable == true
    end

    test "does not turn tile to rubble for non-destructible entity" do
      state = build_state() |> with_entity(monster_id(), hp: 1)
      monster_pos = {state.entities[monster_id()].x, state.entities[monster_id()].y}
      updated = Rules.attack(state, hero_id(), monster_id())

      tile = updated.grid_tiles[monster_pos]
      refute tile.texture == "rubble"
    end
  end
end
