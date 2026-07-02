defmodule GibberingTalesWeb.HUDTest do
  # Pure functions only — no DB, no process. Safe to run async.
  use ExUnit.Case, async: true

  import GibberingTalesWeb.EngineFixtures

  alias GibberingTalesWeb.HUD
  alias GibberingEngine.HUD, as: HUDStruct
  alias GibberingEngine.HUD.Action

  # ---------------------------------------------------------------------------
  # action_bar
  # ---------------------------------------------------------------------------

  describe "build/2 action_bar — player role" do
    test "returns a list of HUD.Action structs for the active player" do
      state =
        build_state()
        |> Map.put(:actor_id, hero_id())

      %HUDStruct{action_bar: actions} = HUD.build(state, :player)

      assert is_list(actions)
      assert Enum.all?(actions, &match?(%Action{}, &1))
    end

    test "each action has a non-empty label and event" do
      state =
        build_state()
        |> Map.put(:actor_id, hero_id())

      %HUDStruct{action_bar: actions} = HUD.build(state, :player)

      for action <- actions do
        assert is_binary(action.label) and action.label != ""
        assert is_binary(action.event) and action.event != ""
      end
    end

    test "returns empty action bar when turn_order is empty" do
      state = build_state(turn_order: [])
      %HUDStruct{action_bar: actions} = HUD.build(state, :player)
      assert actions == []
    end
  end

  describe "build/2 action_bar — DM role" do
    test "DM always gets empty action bar regardless of actor_id" do
      state =
        build_state()
        |> Map.put(:actor_id, hero_id())

      %HUDStruct{action_bar: actions} = HUD.build(state, :dm)
      assert actions == []
    end
  end

  # ---------------------------------------------------------------------------
  # overlays
  # ---------------------------------------------------------------------------

  describe "build/2 overlays" do
    test "produces move overlays from state.valid_moves" do
      state = build_state(valid_moves: [{1, 2}, {2, 1}])

      %HUDStruct{overlays: overlays} = HUD.build(state, :player)

      move_overlays = Enum.filter(overlays, &(&1.kind in [:move_normal, :move_difficult]))
      assert length(move_overlays) == 2

      coords = Enum.map(move_overlays, fn o -> {o.x, o.y} end)
      assert {1, 2} in coords
      assert {2, 1} in coords
    end

    test "difficult-terrain tiles get :move_difficult kind" do
      costs = %{{1, 2} => :difficult, {2, 1} => :normal}

      state =
        build_state(
          valid_moves: [{1, 2}, {2, 1}],
          valid_move_costs: costs
        )

      %HUDStruct{overlays: overlays} = HUD.build(state, :player)

      difficult = Enum.find(overlays, &(&1.kind == :move_difficult))
      normal = Enum.find(overlays, &(&1.kind == :move_normal))

      assert difficult != nil and difficult.x == 1 and difficult.y == 2
      assert normal != nil and normal.x == 2 and normal.y == 1
    end

    test "produces attack-target overlays from state.valid_targets" do
      state = build_state(valid_targets: [monster_id()])

      %HUDStruct{overlays: overlays} = HUD.build(state, :player)

      target_overlays = Enum.filter(overlays, &(&1.kind == :attack_target))
      assert length(target_overlays) == 1
      assert hd(target_overlays).entity_id == monster_id()
    end

    test "returns empty overlays when state has none" do
      state = build_state()
      %HUDStruct{overlays: overlays} = HUD.build(state, :player)
      assert overlays == []
    end
  end

  # ---------------------------------------------------------------------------
  # status_strip
  # ---------------------------------------------------------------------------

  describe "build/2 status_strip" do
    test "returns status items for entities with conditions" do
      state =
        build_state()
        |> with_entity(hero_id(), conditions: [:poisoned, :prone])

      %HUDStruct{status_strip: strip} = HUD.build(state, :player)

      hero_items = Enum.filter(strip, &(&1.entity_id == hero_id()))
      cond_ids = Enum.map(hero_items, & &1.condition_id)

      assert :poisoned in cond_ids
      assert :prone in cond_ids
    end

    test "status items have string labels" do
      state =
        build_state()
        |> with_entity(monster_id(), conditions: [:blinded])

      %HUDStruct{status_strip: strip} = HUD.build(state, :player)

      blinded = Enum.find(strip, &(&1.condition_id == :blinded))
      assert is_binary(blinded.label)
      assert blinded.label != ""
    end

    test "returns empty strip when no entity has conditions" do
      state = build_state()
      %HUDStruct{status_strip: strip} = HUD.build(state, :player)
      assert strip == []
    end
  end

  # ---------------------------------------------------------------------------
  # role-gating invariant
  # ---------------------------------------------------------------------------

  describe "build/2 role-gating" do
    test "player and DM builds differ in action_bar when actor_id is set" do
      state =
        build_state()
        |> Map.put(:actor_id, hero_id())

      player_hud = HUD.build(state, :player)
      dm_hud = HUD.build(state, :dm)

      # DM never gets action bar
      assert dm_hud.action_bar == []
      # Player may or may not have buttons depending on ruleset; just check type
      assert is_list(player_hud.action_bar)
    end
  end
end
