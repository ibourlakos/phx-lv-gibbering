defmodule GibberingTales.Rulesets.DnD5e.RulesetStateTest do
  use ExUnit.Case, async: true

  alias GibberingTales.Rulesets.DnD5e.RulesetState

  describe "new/0" do
    test "initializes with lobby phase" do
      assert RulesetState.phase(RulesetState.new()) == :lobby
    end

    test "initializes with empty initiative_values" do
      assert RulesetState.initiative_values(RulesetState.new()) == %{}
    end

    test "initializes with empty active_effects" do
      assert RulesetState.active_effects(RulesetState.new()) == []
    end

    test "initializes awaiting_roll as false" do
      refute RulesetState.awaiting_roll?(RulesetState.new())
    end

    test "initializes pending_initiative_rolls as empty MapSet" do
      assert MapSet.size(RulesetState.pending_initiative_rolls(RulesetState.new())) == 0
    end

    test "initializes hidden_entities as empty MapSet" do
      assert MapSet.size(RulesetState.hidden_entities(RulesetState.new())) == 0
    end
  end

  describe "transition_phase/2" do
    test "lobby → exploration is valid" do
      rs = RulesetState.new()
      assert {:ok, new_rs} = RulesetState.transition_phase(rs, :exploration)
      assert RulesetState.phase(new_rs) == :exploration
    end

    test "lobby → in_combat is invalid" do
      assert {:error, _} = RulesetState.transition_phase(RulesetState.new(), :in_combat)
    end

    test "transitioning to same phase is a no-op" do
      rs = RulesetState.new()
      assert {:ok, ^rs} = RulesetState.transition_phase(rs, :lobby)
    end

    test "paused → previous_phase resumes correctly" do
      {:ok, rs} = RulesetState.transition_phase(RulesetState.new(), :exploration)
      {:ok, paused} = RulesetState.transition_phase(rs, :paused)
      assert {:ok, resumed} = RulesetState.transition_phase(paused, :exploration)
      assert RulesetState.phase(resumed) == :exploration
      assert RulesetState.previous_phase(resumed) == nil
    end

    test "paused → wrong phase returns error" do
      {:ok, rs} = RulesetState.transition_phase(RulesetState.new(), :exploration)
      {:ok, paused} = RulesetState.transition_phase(rs, :paused)
      assert {:error, _} = RulesetState.transition_phase(paused, :in_combat)
    end
  end

  describe "force_transition_phase/2" do
    test "can bypass validation to move to any phase" do
      rs = RulesetState.new()
      assert {:ok, new_rs} = RulesetState.force_transition_phase(rs, :victory)
      assert RulesetState.phase(new_rs) == :victory
    end
  end

  describe "initiative" do
    test "set_initiative_value stores the value" do
      rs = RulesetState.set_initiative_value(RulesetState.new(), 42, 18)
      assert RulesetState.initiative_values(rs)[42] == 18
    end
  end

  describe "roll state" do
    test "clear_pending_roll sets awaiting_roll to false and pending_roll to nil" do
      rs =
        RulesetState.new()
        |> RulesetState.set_awaiting_roll(true)
        |> RulesetState.set_pending_roll({:attack, 99})
        |> RulesetState.clear_pending_roll()

      refute RulesetState.awaiting_roll?(rs)
      assert RulesetState.pending_roll(rs) == nil
    end

    test "add/remove pending_initiative_roll" do
      rs = RulesetState.new() |> RulesetState.add_pending_initiative_roll(1)
      assert MapSet.member?(RulesetState.pending_initiative_rolls(rs), 1)
      rs2 = RulesetState.remove_pending_initiative_roll(rs, 1)
      refute MapSet.member?(RulesetState.pending_initiative_rolls(rs2), 1)
    end
  end

  describe "visibility" do
    test "hide_entity / show_entity" do
      rs = RulesetState.new() |> RulesetState.hide_entity(5)
      assert MapSet.member?(RulesetState.hidden_entities(rs), 5)
      rs2 = RulesetState.show_entity(rs, 5)
      refute MapSet.member?(RulesetState.hidden_entities(rs2), 5)
    end

    test "toggle_visibility alternates membership" do
      rs = RulesetState.new()
      once = RulesetState.toggle_visibility(rs, 7)
      assert MapSet.member?(RulesetState.hidden_entities(once), 7)
      twice = RulesetState.toggle_visibility(once, 7)
      refute MapSet.member?(RulesetState.hidden_entities(twice), 7)
    end
  end

  describe "add_log_entry/2" do
    test "prepends to session_log" do
      rs = RulesetState.new() |> RulesetState.add_log_entry("hello")
      assert hd(RulesetState.session_log(rs)) == "hello"
    end
  end

  describe "active effects" do
    test "add_active_effect / remove_active_effects_for" do
      effect = %{
        id: 1,
        entity_id: 10,
        condition_id: :poisoned,
        conditions: [:poisoned],
        source: :unknown,
        duration: nil
      }

      rs = RulesetState.new() |> RulesetState.add_active_effect(effect)
      assert [^effect] = RulesetState.active_effects(rs)

      {rs2, still_active} = RulesetState.remove_active_effects_for(rs, 10, :poisoned)
      assert RulesetState.active_effects(rs2) == []
      refute still_active
    end
  end
end
