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
        x: 1,
        y: 1,
        hp: 8,
        max_hp: 8,
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

    test "resets action_economy for the entity whose turn begins" do
      state =
        with_entity(build_state(), hero_id(),
          action_economy: %{
            action: :spent,
            bonus_action: :spent,
            reaction: :spent,
            movement_remaining: 0
          }
        )

      advanced = State.advance_turn(state)

      assert advanced.entities[hero_id()].action_economy == %{
               action: :available,
               bonus_action: :available,
               reaction: :available,
               movement_remaining: 30
             }
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
          x: 0,
          y: 0,
          hp: 20,
          max_hp: 20,
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
      assert state.grid_tiles[{0, 0}] == %{texture: "grass", walkable: true, decoration: nil}
      assert state.grid_tiles[{1, 0}] == %{texture: "stone", walkable: false, decoration: nil}
      assert state.entities[10].name == "Warrior"
      assert state.turn_order == [10]
      assert state.active_index == 0
    end

    test "only heroes are included in turn_order" do
      entities = [
        %Gibbering.Entity{
          id: 1,
          name: "Hero",
          type: "hero",
          sprite: "h.png",
          x: 0,
          y: 0,
          hp: 10,
          max_hp: 10,
          tags: [],
          stats: %{},
          campaign_id: 1
        },
        %Gibbering.Entity{
          id: 2,
          name: "Orc",
          type: "monster",
          sprite: "o.png",
          x: 1,
          y: 0,
          hp: 5,
          max_hp: 5,
          tags: [],
          stats: %{},
          campaign_id: 1
        }
      ]

      campaign = %Gibbering.Campaign{
        id: 1,
        name: "T",
        map_width: 2,
        map_height: 1,
        tile_size: 32,
        tiles: [],
        entities: entities
      }

      state = State.from_campaign(campaign)
      assert state.turn_order == [1]
    end

    test "hydrates entities with action_economy, resources, and conditions" do
      entities = [
        %Gibbering.Entity{
          id: 10,
          name: "Wizard",
          type: "hero",
          sprite: "w.png",
          x: 0,
          y: 0,
          hp: 8,
          max_hp: 8,
          level: 1,
          temp_hp: 0,
          class: "wizard",
          race: "human",
          tags: [],
          stats: %{"speed" => 35},
          campaign_id: 1
        }
      ]

      campaign = %Gibbering.Campaign{
        id: 1,
        name: "T",
        map_width: 1,
        map_height: 1,
        tile_size: 32,
        tiles: [],
        entities: entities
      }

      entity = State.from_campaign(campaign).entities[10]

      assert entity.action_economy == %{
               action: :available,
               bonus_action: :available,
               reaction: :available,
               movement_remaining: 35
             }

      assert %{spell_slots: _} = entity.resources
      assert entity.conditions == []
    end

    test "fighter entities get second_wind resource" do
      entities = [
        %Gibbering.Entity{
          id: 5,
          name: "Fighter",
          type: "hero",
          sprite: "f.png",
          x: 0,
          y: 0,
          hp: 12,
          max_hp: 12,
          level: 1,
          temp_hp: 0,
          class: "fighter",
          race: "human",
          tags: [],
          stats: %{},
          campaign_id: 1
        }
      ]

      campaign = %Gibbering.Campaign{
        id: 1,
        name: "T",
        map_width: 1,
        map_height: 1,
        tile_size: 32,
        tiles: [],
        entities: entities
      }

      entity = State.from_campaign(campaign).entities[5]
      assert entity.resources == %{second_wind: 1}
      assert entity.conditions == []
    end
  end

  describe "consume_action/3" do
    test "marks an available slot as spent" do
      state = build_state()
      assert {:ok, new_state} = State.consume_action(state, hero_id(), :action)
      assert new_state.entities[hero_id()].action_economy.action == :spent
    end

    test "returns error when slot is already spent" do
      state =
        with_entity(build_state(), hero_id(),
          action_economy: %{
            action: :spent,
            bonus_action: :available,
            reaction: :available,
            movement_remaining: 30
          }
        )

      assert {:error, :already_spent} = State.consume_action(state, hero_id(), :action)
    end

    test "consuming bonus_action does not affect action slot" do
      state = build_state()
      {:ok, new_state} = State.consume_action(state, hero_id(), :bonus_action)
      assert new_state.entities[hero_id()].action_economy.action == :available
      assert new_state.entities[hero_id()].action_economy.bonus_action == :spent
    end
  end

  describe "consume_movement/3" do
    test "deducts feet from movement_remaining" do
      state = build_state()
      assert {:ok, new_state} = State.consume_movement(state, hero_id(), 15)
      assert new_state.entities[hero_id()].action_economy.movement_remaining == 15
    end

    test "returns error when insufficient movement" do
      state =
        with_entity(build_state(), hero_id(),
          action_economy: %{
            action: :available,
            bonus_action: :available,
            reaction: :available,
            movement_remaining: 5
          }
        )

      assert {:error, :insufficient_movement} = State.consume_movement(state, hero_id(), 10)
    end

    test "allows exact spend to zero" do
      state =
        with_entity(build_state(), hero_id(),
          action_economy: %{
            action: :available,
            bonus_action: :available,
            reaction: :available,
            movement_remaining: 10
          }
        )

      assert {:ok, new_state} = State.consume_movement(state, hero_id(), 10)
      assert new_state.entities[hero_id()].action_economy.movement_remaining == 0
    end
  end

  describe "consume_resource/3" do
    test "decrements a class resource charge" do
      state = with_entity(build_state(), hero_id(), resources: %{second_wind: 1})
      assert {:ok, new_state} = State.consume_resource(state, hero_id(), :second_wind)
      assert new_state.entities[hero_id()].resources.second_wind == 0
    end

    test "returns error when no charges remain" do
      state = with_entity(build_state(), hero_id(), resources: %{second_wind: 0})
      assert {:error, :no_charges} = State.consume_resource(state, hero_id(), :second_wind)
    end
  end

  describe "consume_spell_slot/3" do
    test "decrements a spell slot at the given level" do
      state = with_entity(build_state(), hero_id(), resources: %{spell_slots: %{1 => 3, 2 => 2}})
      assert {:ok, new_state} = State.consume_spell_slot(state, hero_id(), 1)
      assert new_state.entities[hero_id()].resources.spell_slots[1] == 2
      assert new_state.entities[hero_id()].resources.spell_slots[2] == 2
    end

    test "returns error when no slots at the requested level" do
      state = with_entity(build_state(), hero_id(), resources: %{spell_slots: %{1 => 0}})
      assert {:error, :no_slots} = State.consume_spell_slot(state, hero_id(), 1)
    end
  end

  describe "apply_long_rest/2" do
    test "restores spell slots to initial values" do
      state =
        with_entity(build_state(), hero_id(),
          resources: %{spell_slots: %{1 => 0}},
          class: "wizard",
          level: 1
        )

      assert {:ok, new_state} = State.apply_long_rest(state, hero_id())
      assert new_state.entities[hero_id()].resources.spell_slots[1] == 2
    end
  end

  describe "apply_short_rest/2" do
    test "restores Fighter second_wind and action_surge" do
      state =
        with_entity(build_state(), hero_id(),
          resources: %{second_wind: 0, action_surge: 0},
          class: "fighter",
          level: 2
        )

      assert {:ok, new_state} = State.apply_short_rest(state, hero_id())
      assert new_state.entities[hero_id()].resources.second_wind == 1
      assert new_state.entities[hero_id()].resources.action_surge == 1
    end
  end
end
