defmodule Gibbering.Engine.StateTest do
  # Pure state transforms — no DB, no process.
  use ExUnit.Case, async: true

  import Gibbering.GameFixtures
  alias Gibbering.Engine.State

  describe "active_hero_id/1" do
    test "returns the hero at active_index" do
      state = build_state()
      assert State.active_hero_id(state) == hero_id()
    end

    test "returns nil when turn_order is empty" do
      state = %{build_state() | turn_order: []}
      assert State.active_hero_id(state) == nil
    end
  end

  describe "advance_turn/1" do
    test "wraps back to index 0 after the last hero" do
      # Only one hero in the default state, so advancing always stays at 0.
      state = build_state()
      advanced = State.advance_turn(state)
      assert advanced.active_index == 0
    end

    test "increments index when multiple heroes exist" do
      second_hero = %{
        name: "Ranger",
        type: "hero",
        sprite: "ranger.png",
        x: 1, y: 1,
        hp: 8, max_hp: 8,
        tags: [],
        stats: %{"speed" => 30}
      }

      state = %{
        build_state()
        | entities: Map.put(build_state().entities, 99, second_hero),
          turn_order: [hero_id(), 99]
      }

      advanced = State.advance_turn(state)
      assert advanced.active_index == 1
      assert State.active_hero_id(advanced) == 99
    end

    test "clears selected_id and valid_moves on advance" do
      state = %{build_state() | selected_id: hero_id(), valid_moves: [{1, 1}, {2, 1}]}
      advanced = State.advance_turn(state)
      assert advanced.selected_id == nil
      assert advanced.valid_moves == []
    end
  end

  describe "from_campaign/1" do
    test "builds state from campaign struct" do
      tiles = [
        %Gibbering.GridTile{x: 0, y: 0, texture: "grass", walkable: true, campaign_id: 1},
        %Gibbering.GridTile{x: 1, y: 0, texture: "stone", walkable: false, campaign_id: 1}
      ]

      entities = [
        %Gibbering.Entity{
          id: 10,
          name: "Warrior",
          type: "hero",
          sprite: "warrior.png",
          x: 0, y: 0,
          hp: 20, max_hp: 20,
          tags: [],
          stats: %{"speed" => 25},
          campaign_id: 1
        }
      ]

      campaign = %Gibbering.Campaign{
        id: 1,
        name: "Test",
        map_width: 2,
        map_height: 1,
        tile_size: 32,
        tiles: tiles,
        entities: entities
      }

      state = State.from_campaign(campaign)

      assert state.map_width == 2
      assert state.map_height == 1
      assert state.grid_tiles[{0, 0}] == %{texture: "grass", walkable: true}
      assert state.grid_tiles[{1, 0}] == %{texture: "stone", walkable: false}
      assert state.entities[10].name == "Warrior"
      assert state.turn_order == [10]
      assert state.active_index == 0
    end

    test "only heroes are included in turn_order" do
      entities = [
        %Gibbering.Entity{
          id: 1, name: "Hero", type: "hero", sprite: "h.png",
          x: 0, y: 0, hp: 10, max_hp: 10, tags: [], stats: %{}, campaign_id: 1
        },
        %Gibbering.Entity{
          id: 2, name: "Orc", type: "monster", sprite: "o.png",
          x: 1, y: 0, hp: 5, max_hp: 5, tags: [], stats: %{}, campaign_id: 1
        }
      ]

      campaign = %Gibbering.Campaign{
        id: 1, name: "T", map_width: 2, map_height: 1, tile_size: 32,
        tiles: [], entities: entities
      }

      state = State.from_campaign(campaign)
      assert state.turn_order == [1]
    end
  end
end
