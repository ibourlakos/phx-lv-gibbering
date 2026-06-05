defmodule Gibbering.Rulesets.DnD5eTest do
  use ExUnit.Case, async: true

  alias Gibbering.Rulesets.DnD5e

  # Minimal entity map sufficient for all callbacks.
  defp entity(overrides \\ []) do
    Map.merge(%{class: "fighter", speed: 30}, Map.new(overrides))
  end

  describe "collect_modifiers/3" do
    test "returns an empty list for any input" do
      assert DnD5e.collect_modifiers(entity(), :move, %{}) == []
    end
  end

  describe "initial_resources/1" do
    test "non-spellcasting classes return empty map" do
      assert DnD5e.initial_resources(entity(class: "fighter")) == %{}
    end

    test "wizard gets spell slots" do
      resources = DnD5e.initial_resources(entity(class: "wizard"))
      assert %{spell_slots: slots} = resources
      assert is_map(slots)
      assert Map.has_key?(slots, 1)
    end

    test "warlock gets pact_slots instead of spell_slots" do
      resources = DnD5e.initial_resources(entity(class: "warlock"))
      assert %{pact_slots: 1} = resources
    end

    test "cleric, sorcerer, bard, druid also get spell slots" do
      for class <- ~w(cleric sorcerer bard druid) do
        assert %{spell_slots: _} = DnD5e.initial_resources(entity(class: class)),
               "#{class} should have spell_slots"
      end
    end

    test "paladin and ranger get spell_slots" do
      for class <- ~w(paladin ranger) do
        assert %{spell_slots: _} = DnD5e.initial_resources(entity(class: class)),
               "#{class} should have spell_slots"
      end
    end
  end

  describe "initial_action_economy/1" do
    test "returns full action economy based on entity speed" do
      ae = DnD5e.initial_action_economy(entity(speed: 30))

      assert ae == %{action: 1, bonus_action: 1, reaction: 1, movement: 30}
    end

    test "uses entity speed as movement value" do
      ae = DnD5e.initial_action_economy(entity(speed: 25))
      assert ae.movement == 25
    end

    test "falls back to 30 when speed is absent" do
      ae = DnD5e.initial_action_economy(%{class: "fighter"})
      assert ae.movement == 30
    end
  end

  describe "advance_turn/1" do
    test "resets action_economy to full values" do
      spent = entity(speed: 30) |> Map.put(:action_economy, %{action: 0, movement: 0})
      refreshed = DnD5e.advance_turn(spent)

      assert refreshed.action_economy == %{
               action: 1,
               bonus_action: 1,
               reaction: 1,
               movement: 30
             }
    end

    test "preserves other entity fields" do
      e = entity(speed: 30) |> Map.put(:hp, 15)
      refreshed = DnD5e.advance_turn(e)
      assert refreshed.hp == 15
    end
  end
end
