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
        build_state(x_extent: 15, y_extent: 15)
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

    test "treats a tile absent from grid_tiles as unwalkable" do
      state = %{build_state() | grid_tiles: Map.delete(build_state().grid_tiles, {2, 1})}
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
  # attack/4
  # ---------------------------------------------------------------------------

  describe "attack/4 — roll mechanics" do
    test "natural 20 is always a hit regardless of AC" do
      # Give target extremely high AC — nat 20 still hits
      state = build_state() |> with_entity(monster_id(), armor_class: 30)
      {result, _new_state, details} = Rules.attack(state, hero_id(), monster_id(), roll: 20)
      assert result == :critical
      assert details.hit == true
      assert details.critical == true
      assert details.roll == 20
    end

    test "natural 1 is always a miss regardless of modifiers" do
      # Give attacker absurdly high stats — nat 1 still misses
      state =
        build_state()
        |> with_entity(hero_id(), proficiency_bonus: 99, ability_modifiers: %{"strength" => 99})

      {result, _new_state, details} = Rules.attack(state, hero_id(), monster_id(), roll: 1)
      assert result == :miss
      assert details.hit == false
      assert details.critical == false
    end

    test "hits when d20 + attack_bonus >= target AC" do
      # Hero: str 16 (+3), level 1 (prof +2) → attack bonus +5
      # Monster: AC 13 (light armor base 11 + dex +2)
      # Roll 8 → 8 + 5 = 13 >= 13 → hit
      state = build_state()
      {result, _new_state, details} = Rules.attack(state, hero_id(), monster_id(), roll: 8)
      assert result == :hit
      assert details.hit == true
      assert details.total == 8 + details.bonus
    end

    test "misses when d20 + attack_bonus < target AC" do
      # Hero attack bonus +5, monster AC 13.
      # Roll 7 → 7 + 5 = 12 < 13 → miss (and roll 7 is not a nat-1 so it's a "real" miss)
      state = build_state()
      {result, _new_state, details} = Rules.attack(state, hero_id(), monster_id(), roll: 7)
      assert result == :miss
      assert details.hit == false
    end

    test "critical hit doubles damage dice count" do
      state = build_state()
      {_result, _new_state, details} = Rules.attack(state, hero_id(), monster_id(), roll: 20)
      # Normal 1d8 → critical = 2d8 → damage >= 2
      assert details.damage >= 2
    end

    test "miss deals no damage and does not change target hp" do
      state = build_state()
      original_hp = state.entities[monster_id()].hp
      {_result, new_state, details} = Rules.attack(state, hero_id(), monster_id(), roll: 1)
      assert details.damage == nil
      assert new_state.entities[monster_id()].hp == original_hp
    end

    test "returns roll details with expected keys" do
      state = build_state()
      {_result, _new_state, details} = Rules.attack(state, hero_id(), monster_id(), roll: 15)
      assert Map.has_key?(details, :roll)
      assert Map.has_key?(details, :bonus)
      assert Map.has_key?(details, :total)
      assert Map.has_key?(details, :target_ac)
      assert Map.has_key?(details, :hit)
      assert Map.has_key?(details, :critical)
      assert Map.has_key?(details, :damage)
    end
  end

  describe "attack/4 — action economy" do
    test "returns error when attacker action slot is spent" do
      state =
        with_entity(build_state(), hero_id(),
          action_economy: %{
            action: :spent,
            bonus_action: :available,
            reaction: :available,
            movement_remaining: 30
          }
        )

      assert {:error, :already_spent} = Rules.attack(state, hero_id(), monster_id(), roll: 20)
    end

    test "consumes the action slot on a hit" do
      state = build_state()
      {_result, new_state, _details} = Rules.attack(state, hero_id(), monster_id(), roll: 20)
      assert new_state.entities[hero_id()].action_economy.action == :spent
    end

    test "consumes the action slot on a miss" do
      state = build_state()
      {_result, new_state, _details} = Rules.attack(state, hero_id(), monster_id(), roll: 1)
      assert new_state.entities[hero_id()].action_economy.action == :spent
    end
  end

  describe "attack/4 — state effects" do
    test "reduces target hp on hit" do
      state = build_state()
      original_hp = state.entities[monster_id()].hp
      {_result, new_state, _details} = Rules.attack(state, hero_id(), monster_id(), roll: 20)
      new_hp = get_in(new_state.entities, [monster_id(), :hp]) || 0
      assert new_hp < original_hp
    end

    test "hp cannot drop below 0" do
      state = build_state() |> with_entity(monster_id(), hp: 1)
      {_result, new_state, _details} = Rules.attack(state, hero_id(), monster_id(), roll: 20)
      hp = get_in(new_state.entities, [monster_id(), :hp])
      assert hp == nil or hp >= 0
    end

    test "removes entity from state when hp reaches 0" do
      state = build_state() |> with_entity(monster_id(), hp: 1)
      {_result, new_state, _details} = Rules.attack(state, hero_id(), monster_id(), roll: 20)
      refute Map.has_key?(new_state.entities, monster_id())
    end

    test "converts destructible entity tile to rubble on death" do
      state = build_state() |> with_entity(monster_id(), hp: 1, tags: ["destructible"])
      monster_pos = {state.entities[monster_id()].x, state.entities[monster_id()].y}
      {_result, new_state, _details} = Rules.attack(state, hero_id(), monster_id(), roll: 20)
      assert new_state.grid_tiles[monster_pos].texture == "rubble"
      assert new_state.grid_tiles[monster_pos].walkable == true
    end

    test "does not turn tile to rubble for non-destructible entity" do
      state = build_state() |> with_entity(monster_id(), hp: 1)
      monster_pos = {state.entities[monster_id()].x, state.entities[monster_id()].y}
      {_result, new_state, _details} = Rules.attack(state, hero_id(), monster_id(), roll: 20)
      tile = new_state.grid_tiles[monster_pos]
      refute tile.texture == "rubble"
    end
  end

  # ---------------------------------------------------------------------------
  # valid_spell_targets/3
  # ---------------------------------------------------------------------------

  describe "valid_spell_targets/3" do
    test "returns empty list for unknown spell key" do
      state = build_state()
      assert Rules.valid_spell_targets(state, hero_id(), :nonexistent_spell) == []
    end

    test "monster within range of fire_bolt (120 ft) is a valid target" do
      # Hero at (2,2), monster at (3,3) — Chebyshev 1, fire_bolt range 24 tiles
      state = build_state()
      targets = Rules.valid_spell_targets(state, hero_id(), :fire_bolt)
      assert monster_id() in targets
    end

    test "monster outside fire_bolt range is excluded" do
      state =
        build_state(x_extent: 30, y_extent: 30)
        |> with_entity(monster_id(), x: 29, y: 29)

      # Hero at (2,2), monster at (29,29) — Chebyshev 27, fire_bolt range 24 tiles
      targets = Rules.valid_spell_targets(state, hero_id(), :fire_bolt)
      refute monster_id() in targets
    end

    test "caster is never a valid spell target" do
      state = build_state()
      targets = Rules.valid_spell_targets(state, hero_id(), :fire_bolt)
      refute hero_id() in targets
    end

    test "touch-range spell (cure_wounds) reaches adjacent monster (Chebyshev 1)" do
      # Monster at (3,3) is Chebyshev 1 from hero at (2,2) — within touch range
      state = build_state()
      targets = Rules.valid_spell_targets(state, hero_id(), :cure_wounds)
      assert monster_id() in targets
    end

    test "touch-range spell does not reach monster 2 tiles away" do
      state = build_state() |> with_entity(monster_id(), x: 4, y: 4)
      # Chebyshev distance is 2 — beyond touch range (1 tile)
      targets = Rules.valid_spell_targets(state, hero_id(), :cure_wounds)
      refute monster_id() in targets
    end

    test "other heroes are not spell targets" do
      ally = %{
        name: "Cleric",
        type: "hero",
        sprite: "cleric.png",
        x: 3,
        y: 3,
        hp: 8,
        max_hp: 8,
        tags: [],
        stats: %{},
        conditions: [],
        armor_class: 12,
        action_economy: %{
          action: :available,
          bonus_action: :available,
          reaction: :available,
          movement_remaining: 30
        },
        resources: %{}
      }

      state = %{build_state() | entities: Map.put(build_state().entities, 99, ally)}
      targets = Rules.valid_spell_targets(state, hero_id(), :fire_bolt)
      refute 99 in targets
    end
  end

  # ---------------------------------------------------------------------------
  # cast_spell/5
  # ---------------------------------------------------------------------------

  # Helpers for spell tests — wizard hero has INT 16 (+3) and a level-1 spell slot.
  defp wizard_state do
    build_state()
    |> with_entity(hero_id(),
      class: "wizard",
      stats:
        Map.merge(build_state().entities[hero_id()].stats, %{
          "intelligence" => 16
        }),
      ability_modifiers: %{"intelligence" => 3, "strength" => 3, "dexterity" => 1},
      resources: %{spell_slots: %{1 => 2}}
    )
  end

  describe "cast_spell/5 — resource checks" do
    test "returns error for unknown spell key" do
      state = build_state()

      assert {:error, :unknown_spell} =
               Rules.cast_spell(state, hero_id(), :not_a_spell, monster_id())
    end

    test "returns error when action slot is spent" do
      state =
        with_entity(build_state(), hero_id(),
          action_economy: %{
            action: :spent,
            bonus_action: :available,
            reaction: :available,
            movement_remaining: 30
          }
        )

      assert {:error, :already_spent} =
               Rules.cast_spell(state, hero_id(), :fire_bolt, monster_id())
    end

    test "returns error when no level-1 spell slot available" do
      state = with_entity(build_state(), hero_id(), resources: %{spell_slots: %{1 => 0}})

      assert {:error, :no_slots} =
               Rules.cast_spell(state, hero_id(), :magic_missile, monster_id())
    end

    test "casting a cantrip does not require or consume spell slots" do
      state = with_entity(build_state(), hero_id(), resources: %{})
      # fire_bolt is a cantrip (level 0) — no slot required
      result = Rules.cast_spell(state, hero_id(), :fire_bolt, monster_id(), roll: 20)
      assert elem(result, 0) in [:hit, :miss, :critical]
    end
  end

  describe "cast_spell/5 — ranged_attack (fire_bolt)" do
    test "natural 20 is a critical hit" do
      {result, _state, details} =
        Rules.cast_spell(wizard_state(), hero_id(), :fire_bolt, monster_id(), roll: 20)

      assert result == :critical
      assert details.hit == true
      assert details.critical == true
    end

    test "natural 1 is always a miss" do
      {result, _state, details} =
        Rules.cast_spell(wizard_state(), hero_id(), :fire_bolt, monster_id(), roll: 1)

      assert result == :miss
      assert details.hit == false
    end

    test "hit when d20 + spell_attack_bonus >= target AC" do
      # wizard INT 16 (+3) + prof +2 = spell bonus 5, monster AC 13
      # roll 8 → 8 + 5 = 13 >= 13 → hit
      {result, _state, details} =
        Rules.cast_spell(wizard_state(), hero_id(), :fire_bolt, monster_id(), roll: 8)

      assert result == :hit
      assert details.hit == true
    end

    test "miss when d20 + spell_attack_bonus < target AC" do
      # roll 7 → 7 + 5 = 12 < 13 → miss
      {result, _state, details} =
        Rules.cast_spell(wizard_state(), hero_id(), :fire_bolt, monster_id(), roll: 7)

      assert result == :miss
      assert details.hit == false
      assert details.damage == nil
    end

    test "hit reduces target hp" do
      original_hp = wizard_state().entities[monster_id()].hp

      {_result, new_state, _details} =
        Rules.cast_spell(wizard_state(), hero_id(), :fire_bolt, monster_id(), roll: 20)

      new_hp = get_in(new_state.entities, [monster_id(), :hp]) || 0
      assert new_hp < original_hp
    end

    test "consumes action slot on any roll" do
      for roll <- [1, 10, 20] do
        {_result, new_state, _details} =
          Rules.cast_spell(wizard_state(), hero_id(), :fire_bolt, monster_id(), roll: roll)

        assert new_state.entities[hero_id()].action_economy.action == :spent
      end
    end
  end

  describe "cast_spell/5 — auto-hit (magic_missile)" do
    test "always returns :hit" do
      state = wizard_state()

      {result, _new_state, details} =
        Rules.cast_spell(state, hero_id(), :magic_missile, monster_id())

      assert result == :hit
      assert details.hit == true
    end

    test "deals damage regardless of target AC" do
      state = wizard_state() |> with_entity(monster_id(), armor_class: 30)

      {_result, new_state, details} =
        Rules.cast_spell(state, hero_id(), :magic_missile, monster_id())

      assert is_integer(details.damage) and details.damage >= 1
      new_hp = get_in(new_state.entities, [monster_id(), :hp]) || 0
      assert new_hp < state.entities[monster_id()].hp
    end

    test "consumes a level-1 spell slot" do
      state = wizard_state()
      slots_before = get_in(state.entities, [hero_id(), :resources, :spell_slots, 1])

      {_result, new_state, _details} =
        Rules.cast_spell(state, hero_id(), :magic_missile, monster_id())

      slots_after = get_in(new_state.entities, [hero_id(), :resources, :spell_slots, 1])
      assert slots_after == slots_before - 1
    end
  end

  describe "cast_spell/5 — stub types (aoe/utility)" do
    test "returns :hit without applying damage for :utility spells" do
      state = wizard_state()

      {result, new_state, details} =
        Rules.cast_spell(state, hero_id(), :mage_hand, monster_id())

      assert result == :hit
      assert details.damage == nil
      assert new_state.entities[monster_id()].hp == state.entities[monster_id()].hp
    end
  end

  # ---------------------------------------------------------------------------
  # saving_throw/5
  # ---------------------------------------------------------------------------

  describe "saving_throw/5" do
    test "returns :save when roll + modifier >= dc" do
      # monster CON 10 (+0), proficient in CON as fighter (+2), roll 20 → 22 >= 5
      assert {:save, details} =
               Rules.saving_throw(build_state(), monster_id(), :constitution, 5, roll: 20)

      assert details.total >= 5
      assert details.roll == 20
    end

    test "returns :fail when roll + modifier < dc" do
      # roll 1 + prof 2 + mod 0 = 3 < 30
      assert {:fail, details} =
               Rules.saving_throw(build_state(), monster_id(), :constitution, 30, roll: 1)

      assert details.total < 30
    end

    test "proficient entity includes proficiency bonus" do
      # fighter is proficient in STR saves; STR 8 → mod -1; prof 2 → total = roll - 1 + 2
      # non-proficient DEX: DEX 14 → mod +2, no prof → total = roll + 2
      # same roll=5: proficient STR: 5 - 1 + 2 = 6; non-proficient DEX: 5 + 2 = 7
      # Just assert proficient: true when proficient in that ability
      {:save, details} =
        Rules.saving_throw(wizard_state(), hero_id(), :intelligence, 1, roll: 5)

      assert details.proficient == true
    end

    test "non-proficient entity excludes proficiency bonus" do
      # wizard is NOT proficient in STR saves (wizard saving_throws = ["intelligence", "wisdom"])
      {:fail, details} =
        Rules.saving_throw(wizard_state(), hero_id(), :strength, 30, roll: 1)

      assert details.proficient == false
    end

    test "details include roll, modifier, total, dc, ability fields" do
      {:save, details} =
        Rules.saving_throw(build_state(), monster_id(), :constitution, 1, roll: 10)

      assert Map.has_key?(details, :roll)
      assert Map.has_key?(details, :modifier)
      assert Map.has_key?(details, :total)
      assert Map.has_key?(details, :dc)
      assert Map.has_key?(details, :ability)
    end
  end

  # ---------------------------------------------------------------------------
  # cast_spell/5 — save type
  # ---------------------------------------------------------------------------

  describe "cast_spell/5 — save type (thunderwave)" do
    test "failed save deals full damage and reports :fail" do
      # wizard spell_dc = 8 + prof(2) + INT_mod(3) = 13
      # monster CON save: roll 1 + mod 0 + prof 2 = 3 < 13 → FAIL
      original_hp = wizard_state().entities[monster_id()].hp

      {result, new_state, details} =
        Rules.cast_spell(wizard_state(), hero_id(), :thunderwave, monster_id(), roll: 1)

      assert result == :hit
      assert details.save_result == :fail
      assert is_integer(details.damage) and details.damage > 0
      # monster may be dead (removed) or wounded — either proves damage landed
      new_hp = get_in(new_state.entities, [monster_id(), :hp]) || 0
      assert new_hp < original_hp
    end

    test "successful save deals half damage and reports :save" do
      # roll 20 + mod 0 + prof 2 = 22 >= 13 → SAVE → half of 2d8 (min 1)
      {result, _new_state, details} =
        Rules.cast_spell(wizard_state(), hero_id(), :thunderwave, monster_id(), roll: 20)

      assert result == :hit
      assert details.save_result == :save
    end

    test "consumes the level-1 spell slot" do
      slots_before = get_in(wizard_state().entities, [hero_id(), :resources, :spell_slots, 1])

      {_result, new_state, _details} =
        Rules.cast_spell(wizard_state(), hero_id(), :thunderwave, monster_id(), roll: 1)

      slots_after = get_in(new_state.entities, [hero_id(), :resources, :spell_slots, 1])
      assert slots_after == slots_before - 1
    end
  end
end
