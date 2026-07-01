defmodule Gibbering.Engine.EntityMovementTest do
  use ExUnit.Case, async: true

  import Gibbering.GameFixtures
  alias Gibbering.Engine.Rules
  alias Gibbering.Rulesets.DnD5e
  alias GibberingEngine.RuleModifier
  alias Gibbering.Rulesets.DnD5e.{Stats, Condition}

  # ---------------------------------------------------------------------------
  # Stats.speed_for_mode/2
  # ---------------------------------------------------------------------------

  describe "Stats.speed_for_mode/2" do
    test "walk returns stats[speed] with default 30" do
      entity = %{stats: %{"speed" => 35}}
      assert Stats.speed_for_mode(entity, "walk") == 35
    end

    test "walk defaults to 30 when speed key absent" do
      entity = %{stats: %{}}
      assert Stats.speed_for_mode(entity, "walk") == 30
    end

    test "fly returns stats[fly_speed] (nil when absent)" do
      entity = %{stats: %{"fly_speed" => 60}}
      assert Stats.speed_for_mode(entity, "fly") == 60
    end

    test "fly returns nil when fly_speed absent" do
      entity = %{stats: %{"speed" => 30}}
      assert Stats.speed_for_mode(entity, "fly") == nil
    end

    test "climb returns stats[climb_speed]" do
      entity = %{stats: %{"climb_speed" => 20}}
      assert Stats.speed_for_mode(entity, "climb") == 20
    end

    test "climb returns nil when climb_speed absent" do
      entity = %{stats: %{}}
      assert Stats.speed_for_mode(entity, "climb") == nil
    end

    test "swim returns stats[swim_speed]" do
      entity = %{stats: %{"swim_speed" => 25}}
      assert Stats.speed_for_mode(entity, "swim") == 25
    end

    test "unknown mode returns nil" do
      entity = %{stats: %{"speed" => 30}}
      assert Stats.speed_for_mode(entity, "teleport") == nil
    end
  end

  # ---------------------------------------------------------------------------
  # Rules.movement_cost_ft/2
  # ---------------------------------------------------------------------------

  describe "Rules.movement_cost_ft/2" do
    test "permission 100 costs 5 ft (one normal tile)" do
      assert Rules.movement_cost_ft(100) == 5
    end

    test "permission 50 costs 10 ft (difficult terrain, x2)" do
      assert Rules.movement_cost_ft(50) == 10
    end

    test "permission 25 costs 20 ft (very difficult, x4)" do
      assert Rules.movement_cost_ft(25) == 20
    end

    test "respects custom tile_size" do
      assert Rules.movement_cost_ft(100, 10) == 10
      assert Rules.movement_cost_ft(50, 10) == 20
    end
  end

  # ---------------------------------------------------------------------------
  # Rules.valid_moves/3 — multi-mode
  # ---------------------------------------------------------------------------

  describe "valid_moves/3 multi-mode" do
    test "default mode is walk (backward compatible with 2-arity call)" do
      state = build_state()
      assert Rules.valid_moves(state, hero_id()) == Rules.valid_moves(state, hero_id(), "walk")
    end

    test "fly mode returns [] when entity has no fly_speed" do
      state = build_state()
      assert Rules.valid_moves(state, hero_id(), "fly") == []
    end

    test "fly mode returns moves when entity has fly_speed" do
      state =
        build_state()
        |> with_entity(hero_id(), stats: %{"speed" => 30, "fly_speed" => 30})

      moves = Rules.valid_moves(state, hero_id(), "fly")
      refute moves == []
    end

    test "fly mode allows movement over tiles with no walk permission but fly permission" do
      state =
        build_state()
        |> with_entity(hero_id(), stats: %{"speed" => 30, "fly_speed" => 30})
        |> with_tile({3, 2}, movement: %{"fly" => 100})

      moves = Rules.valid_moves(state, hero_id(), "fly")
      assert {3, 2} in moves
    end

    test "fly mode excludes tiles with no fly permission (fly value 0 or absent)" do
      state =
        build_state()
        |> with_entity(hero_id(), stats: %{"speed" => 30, "fly_speed" => 30})
        |> with_tile({3, 2}, movement: %{"walk" => 100})

      moves = Rules.valid_moves(state, hero_id(), "fly")
      refute {3, 2} in moves
    end

    test "climb mode returns [] when entity has no climb_speed" do
      state = build_state()
      assert Rules.valid_moves(state, hero_id(), "climb") == []
    end

    test "climb mode uses climb_speed for range calculation" do
      state =
        build_state()
        |> with_entity(hero_id(), stats: %{"speed" => 30, "climb_speed" => 10})
        |> with_tile({2, 3}, movement: %{"climb" => 100})

      moves = Rules.valid_moves(state, hero_id(), "climb")
      assert {2, 3} in moves
    end

    test "swim mode returns [] when entity has no swim_speed" do
      state = build_state()
      assert Rules.valid_moves(state, hero_id(), "swim") == []
    end
  end

  # ---------------------------------------------------------------------------
  # advance_turn — passive speed conditions applied to movement_remaining
  # ---------------------------------------------------------------------------

  describe "advance_turn with speed-zeroing conditions" do
    test "Restrained condition zeroes movement_remaining on advance_turn" do
      entity =
        build_state().actors[hero_id()]
        |> Map.put(:conditions, [:restrained])

      updated = DnD5e.advance_turn(entity)
      assert updated.action_economy.movement_remaining == 0
    end

    test "Grappled condition zeroes movement_remaining on advance_turn" do
      entity =
        build_state().actors[hero_id()]
        |> Map.put(:conditions, [:grappled])

      updated = DnD5e.advance_turn(entity)
      assert updated.action_economy.movement_remaining == 0
    end

    test "No speed-zeroing conditions: movement_remaining = entity walk speed" do
      entity = build_state().actors[hero_id()]
      updated = DnD5e.advance_turn(entity)
      assert updated.action_economy.movement_remaining == 30
    end

    test "Non-movement condition does not affect movement_remaining" do
      entity =
        build_state().actors[hero_id()]
        |> Map.put(:conditions, [:blinded])

      updated = DnD5e.advance_turn(entity)
      assert updated.action_economy.movement_remaining == 30
    end
  end

  # ---------------------------------------------------------------------------
  # Condition definitions — Fly and Spider Climb
  # ---------------------------------------------------------------------------

  describe "Fly and Spider Climb condition definitions" do
    test "Condition.all/0 includes :flying condition" do
      assert Map.has_key?(Condition.all(), :flying)
    end

    test "flying condition has a :grant_speed fly modifier" do
      %{modifiers: mods} = Condition.all()[:flying]

      assert Enum.any?(mods, fn
               %RuleModifier{effect: {:grant_speed, "fly", _}} -> true
               _ -> false
             end)
    end

    test "flying condition grants fly speed of 60 ft" do
      %{modifiers: mods} = Condition.all()[:flying]

      assert Enum.any?(mods, fn
               %RuleModifier{effect: {:grant_speed, "fly", 60}} -> true
               _ -> false
             end)
    end

    test "Condition.all/0 includes :spider_climb condition" do
      assert Map.has_key?(Condition.all(), :spider_climb)
    end

    test "spider_climb condition has a :grant_speed climb modifier" do
      %{modifiers: mods} = Condition.all()[:spider_climb]

      assert Enum.any?(mods, fn
               %RuleModifier{effect: {:grant_speed, "climb", _}} -> true
               _ -> false
             end)
    end

    test "Restrained condition uses :set_all_speeds effect (not :set_speed)" do
      %{modifiers: mods} = Condition.all()[:restrained]

      speed_zero =
        Enum.find(mods, fn
          %RuleModifier{id: :restrained_no_speed} -> true
          _ -> false
        end)

      assert %RuleModifier{effect: {:set_all_speeds, 0}} = speed_zero
    end
  end
end
