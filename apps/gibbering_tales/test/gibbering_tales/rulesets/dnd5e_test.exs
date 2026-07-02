defmodule GibberingTales.Rulesets.DnD5eTest do
  use ExUnit.Case, async: true

  alias GibberingTales.Rulesets.DnD5e

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
    test "fighter gets second_wind at level 1" do
      assert DnD5e.initial_resources(entity(class: "fighter")) == %{second_wind: 1}
    end

    test "unknown class returns empty map" do
      assert DnD5e.initial_resources(entity(class: "artificer")) == %{}
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

    test "wizard level 5 gets 4/3/2 spell slots" do
      resources = DnD5e.initial_resources(entity(class: "wizard", level: 5))
      assert resources.spell_slots == %{1 => 4, 2 => 3, 3 => 2}
    end

    test "paladin level 1 gets no spell slots" do
      resources = DnD5e.initial_resources(entity(class: "paladin", level: 1))
      assert resources.spell_slots == %{}
    end

    test "paladin level 5 gets 4/2 spell slots" do
      resources = DnD5e.initial_resources(entity(class: "paladin", level: 5))
      assert resources.spell_slots == %{1 => 4, 2 => 2}
    end

    test "barbarian gets rage_charges" do
      resources = DnD5e.initial_resources(entity(class: "barbarian", level: 1))
      assert resources.rage_charges == 2
    end

    test "fighter level 2 gets second_wind and action_surge" do
      resources = DnD5e.initial_resources(entity(class: "fighter", level: 2))
      assert resources.second_wind == 1
      assert resources.action_surge == 1
    end

    test "warlock gets pact_slot_level alongside pact_slots" do
      resources = DnD5e.initial_resources(entity(class: "warlock", level: 5))
      assert resources.pact_slots == 2
      assert resources.pact_slot_level == 3
    end
  end

  describe "initial_action_economy/1" do
    test "returns full action economy based on entity speed" do
      ae = DnD5e.initial_action_economy(entity(speed: 30))

      assert ae == %{
               action: :available,
               bonus_action: :available,
               reaction: :available,
               movement_remaining: 30
             }
    end

    test "uses entity speed as movement_remaining value" do
      ae = DnD5e.initial_action_economy(entity(speed: 25))
      assert ae.movement_remaining == 25
    end

    test "falls back to 30 when speed is absent" do
      ae = DnD5e.initial_action_economy(%{class: "fighter"})
      assert ae.movement_remaining == 30
    end
  end

  describe "short_rest_entity/1" do
    test "restores Fighter second_wind and action_surge" do
      e =
        entity(class: "fighter", level: 2)
        |> Map.put(:resources, %{second_wind: 0, action_surge: 0})

      refreshed = DnD5e.short_rest_entity(e)
      assert refreshed.resources.second_wind == 1
      assert refreshed.resources.action_surge == 1
    end

    test "restores Warlock pact slots" do
      e =
        entity(class: "warlock", level: 3)
        |> Map.put(:resources, %{pact_slots: 0, pact_slot_level: 2})

      refreshed = DnD5e.short_rest_entity(e)
      assert refreshed.resources.pact_slots == 2
    end

    test "is a no-op for non-short-rest classes" do
      e = entity(class: "wizard", level: 3) |> Map.put(:resources, %{spell_slots: %{1 => 0}})
      assert DnD5e.short_rest_entity(e) == e
    end
  end

  describe "long_rest_entity/1" do
    test "restores all resources to initial values" do
      e =
        entity(class: "wizard", level: 3)
        |> Map.put(:resources, %{spell_slots: %{1 => 0, 2 => 0}})

      refreshed = DnD5e.long_rest_entity(e)
      assert refreshed.resources.spell_slots[1] == 4
      assert refreshed.resources.spell_slots[2] == 2
    end
  end

  describe "advance_turn/1" do
    test "resets action_economy to full values" do
      spent =
        entity(speed: 30)
        |> Map.put(:action_economy, %{action: :spent, bonus_action: :spent, movement_remaining: 0})

      refreshed = DnD5e.advance_turn(spent)

      assert refreshed.action_economy == %{
               action: :available,
               bonus_action: :available,
               reaction: :available,
               movement_remaining: 30
             }
    end

    test "preserves other entity fields" do
      e = entity(speed: 30) |> Map.put(:hp, 15)
      refreshed = DnD5e.advance_turn(e)
      assert refreshed.hp == 15
    end
  end

  describe "action_buttons/2" do
    test "always returns a Move button as the first button" do
      buttons = DnD5e.action_buttons(entity(), %{})
      [move_btn | _] = buttons
      assert move_btn.event == "activate_move"
      assert Map.has_key?(move_btn, :disabled)
      assert Map.has_key?(move_btn, :sublabel)
    end

    test "Move button is disabled when movement_remaining is 0" do
      e = entity() |> Map.put(:action_economy, %{movement_remaining: 0})
      [move_btn | _] = DnD5e.action_buttons(e, %{})
      assert move_btn.disabled == true
    end

    test "Move button is enabled when movement_remaining > 0" do
      e = entity() |> Map.put(:action_economy, %{movement_remaining: 30})
      [move_btn | _] = DnD5e.action_buttons(e, %{})
      assert move_btn.disabled == false
      assert move_btn.sublabel == "30 ft"
    end

    test "returns Move + one button per spell in stats[\"spells\"]" do
      e = entity() |> Map.put(:stats, %{"spells" => ["fire_bolt", "magic_missile"]})
      buttons = DnD5e.action_buttons(e, %{})
      assert length(buttons) == 3
    end

    test "spell button has required keys" do
      e = entity() |> Map.put(:stats, %{"spells" => ["fire_bolt"]})
      [_move | [btn]] = DnD5e.action_buttons(e, %{})
      assert is_binary(btn.label)
      assert btn.event == "select_spell"
      assert btn.value == %{"key" => "fire_bolt"}
      assert Map.has_key?(btn, :sublabel)
    end

    test "known spell gets display name and level label" do
      e = entity() |> Map.put(:stats, %{"spells" => ["fire_bolt"]})
      [_move | [btn]] = DnD5e.action_buttons(e, %{})
      assert btn.label == "Fire Bolt"
      assert btn.sublabel == "cantrip"
    end

    test "unknown spell key gets humanized name" do
      e = entity() |> Map.put(:stats, %{"spells" => ["custom_blast"]})
      [_move | [btn]] = DnD5e.action_buttons(e, %{})
      assert btn.label == "Custom Blast"
    end
  end

  describe "available_conditions/0" do
    test "returns a non-empty list" do
      assert DnD5e.available_conditions() != []
    end

    test "each entry is {atom, string}" do
      for {id, label} <- DnD5e.available_conditions() do
        assert is_atom(id)
        assert is_binary(label)
      end
    end

    test "includes common D&D 5e conditions" do
      condition_ids = DnD5e.available_conditions() |> Enum.map(&elem(&1, 0))
      assert :poisoned in condition_ids
      assert :paralyzed in condition_ids
    end
  end
end
