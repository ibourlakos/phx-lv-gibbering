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

  describe "apply_condition/4" do
    test "adds an active_effect entry for the entity" do
      state = build_state()
      assert {:ok, new_state} = State.apply_condition(state, hero_id(), :poisoned)
      assert [effect] = new_state.active_effects
      assert effect.entity_id == hero_id()
      assert effect.condition_id == :poisoned
      assert :poisoned in effect.conditions
    end

    test "appends the condition key to entity.conditions" do
      state = build_state()
      {:ok, new_state} = State.apply_condition(state, hero_id(), :poisoned)
      assert :poisoned in new_state.entities[hero_id()].conditions
    end

    test "applying the same condition twice does not duplicate entity.conditions" do
      state = build_state()
      {:ok, s1} = State.apply_condition(state, hero_id(), :poisoned)
      {:ok, s2} = State.apply_condition(s1, hero_id(), :poisoned)
      assert Enum.count(s2.entities[hero_id()].conditions, &(&1 == :poisoned)) == 1
    end

    test "accepts source and duration opts" do
      state = build_state()

      {:ok, new_state} =
        State.apply_condition(state, hero_id(), :blinded, source: :spell, duration: 3)

      [effect] = new_state.active_effects
      assert effect.source == :spell
      assert effect.duration == 3
    end

    test "does not affect other entities" do
      state = build_state()
      {:ok, new_state} = State.apply_condition(state, hero_id(), :poisoned)
      assert new_state.entities[monster_id()].conditions == []
    end
  end

  describe "remove_condition/3" do
    test "removes the active_effect and clears entity.conditions" do
      state = build_state()
      {:ok, with_cond} = State.apply_condition(state, hero_id(), :poisoned)
      assert {:ok, cleared} = State.remove_condition(with_cond, hero_id(), :poisoned)
      assert cleared.active_effects == []
      refute :poisoned in cleared.entities[hero_id()].conditions
    end

    test "removing a non-existent condition is a no-op" do
      state = build_state()
      assert {:ok, same} = State.remove_condition(state, hero_id(), :blinded)
      assert same.active_effects == []
    end

    test "removing one condition does not affect other conditions on the same entity" do
      state = build_state()
      {:ok, s1} = State.apply_condition(state, hero_id(), :poisoned)
      {:ok, s2} = State.apply_condition(s1, hero_id(), :blinded)
      {:ok, s3} = State.remove_condition(s2, hero_id(), :poisoned)
      refute :poisoned in s3.entities[hero_id()].conditions
      assert :blinded in s3.entities[hero_id()].conditions
    end
  end

  describe "set_initiative/3" do
    test "stores the initiative value for the entity" do
      state = build_state()
      new_state = State.set_initiative(state, hero_id(), 15)
      assert new_state.initiative_values[hero_id()] == 15
    end

    test "sorts turn_order by initiative descending after roll" do
      state = %{build_state() | turn_order: [hero_id(), monster_id()]}

      # hero gets lower initiative; monster gets higher → monster should go first
      s1 = State.set_initiative(state, hero_id(), 8)
      s2 = State.set_initiative(s1, monster_id(), 18)

      assert hd(s2.turn_order) == monster_id()
    end

    test "preserves the currently active entity across re-sort" do
      # Start with hero active at index 0, set monster's initiative higher
      state = %{build_state() | turn_order: [hero_id(), monster_id()], active_index: 0}
      s1 = State.set_initiative(state, hero_id(), 20)
      s2 = State.set_initiative(s1, monster_id(), 5)

      # Hero still has highest initiative and is still at front
      assert State.active_hero_id(s2) == hero_id()
    end

    test "stores initiative_values as an empty map by default" do
      state = build_state()
      assert state.initiative_values == %{}
    end
  end

  describe "add_to_turn_order/2" do
    test "appends entity to the end of turn_order" do
      state = build_state()
      new_state = State.add_to_turn_order(state, monster_id())
      assert List.last(new_state.turn_order) == monster_id()
    end

    test "is a no-op if entity is already in turn_order" do
      state = build_state()
      new_state = State.add_to_turn_order(state, hero_id())
      assert new_state.turn_order == state.turn_order
    end

    test "is a no-op if entity_id does not exist in entities" do
      state = build_state()
      new_state = State.add_to_turn_order(state, 9999)
      assert new_state.turn_order == state.turn_order
    end
  end

  describe "remove_from_turn_order/2" do
    test "removes the entity from turn_order" do
      state = %{build_state() | turn_order: [hero_id(), monster_id()]}
      new_state = State.remove_from_turn_order(state, monster_id())
      refute monster_id() in new_state.turn_order
    end

    test "adjusts active_index to stay in bounds when removing" do
      state = %{build_state() | turn_order: [hero_id(), monster_id()], active_index: 1}
      new_state = State.remove_from_turn_order(state, monster_id())
      assert new_state.active_index == 0
    end

    test "is a no-op if entity is not in turn_order" do
      state = build_state()
      new_state = State.remove_from_turn_order(state, 9999)
      assert new_state.turn_order == state.turn_order
    end
  end

  describe "reorder_turn_order/2" do
    test "replaces turn_order with the new order" do
      state = %{build_state() | turn_order: [hero_id(), monster_id()]}
      new_state = State.reorder_turn_order(state, [monster_id(), hero_id()])
      assert new_state.turn_order == [monster_id(), hero_id()]
    end

    test "preserves the currently active entity position after reorder" do
      state = %{build_state() | turn_order: [hero_id(), monster_id()], active_index: 0}
      # Move hero to second position; active entity (hero) should remain active
      new_state = State.reorder_turn_order(state, [monster_id(), hero_id()])
      assert State.active_hero_id(new_state) == hero_id()
    end

    test "ignores ids not currently in turn_order" do
      state = %{build_state() | turn_order: [hero_id()]}
      new_state = State.reorder_turn_order(state, [hero_id(), 9999])
      assert new_state.turn_order == [hero_id()]
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
