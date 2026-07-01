defmodule Gibbering.Data.Items do
  @moduledoc """
  Static reference data for weapons, armour, and consumables.

  All entries are plain maps rather than Ecto schemas — this is a read-only
  catalogue analogous to `Data.Spells`, `Data.Classes`, and `Data.Races`.

  Three item categories are represented:
  - Weapon     — damage_dice, damage_type, weapon_category (:simple | :martial), weapon_properties
  - Armor      — armor_category (:light | :medium | :heavy | :shield | :none), base_ac,
                 stealth_disadvantage, strength_requirement
  - Consumable — charges, effect_description

  All items share: name, item_type, weight_pounds, cost_gp, is_magical, requires_attunement.

  Each item also exposes a `:modifiers` list of `%RuleModifier{}` structs derived
  from its properties (issue #128) — finesse weapons grant a DEX-or-STR attack
  ability choice, armour contributes an AC formula override (or an additive bonus
  for shields). These are surfaced into the `collect_modifiers/3` pipeline when the
  item is equipped. Items with no mechanical effect carry `modifiers: []`.
  """

  alias GibberingEngine.RuleModifier

  @items %{
    # -------------------------------------------------------------------------
    # Simple Weapons
    # -------------------------------------------------------------------------
    "dagger" => %{
      name: "Dagger",
      item_type: :weapon,
      weapon_category: :simple,
      damage_dice: "1d4",
      damage_type: "piercing",
      weapon_properties: ["finesse", "light", "thrown"],
      weight_pounds: 1,
      cost_gp: 2,
      is_magical: false,
      requires_attunement: false
    },
    "handaxe" => %{
      name: "Handaxe",
      item_type: :weapon,
      weapon_category: :simple,
      damage_dice: "1d6",
      damage_type: "slashing",
      weapon_properties: ["light", "thrown"],
      weight_pounds: 2,
      cost_gp: 5,
      is_magical: false,
      requires_attunement: false
    },
    "javelin" => %{
      name: "Javelin",
      item_type: :weapon,
      weapon_category: :simple,
      damage_dice: "1d6",
      damage_type: "piercing",
      weapon_properties: ["thrown"],
      weight_pounds: 2,
      cost_gp: 5,
      is_magical: false,
      requires_attunement: false
    },
    "quarterstaff" => %{
      name: "Quarterstaff",
      item_type: :weapon,
      weapon_category: :simple,
      damage_dice: "1d6",
      damage_type: "bludgeoning",
      weapon_properties: ["versatile"],
      weight_pounds: 4,
      cost_gp: 2,
      is_magical: false,
      requires_attunement: false
    },
    "light_crossbow" => %{
      name: "Light Crossbow",
      item_type: :weapon,
      weapon_category: :simple,
      damage_dice: "1d8",
      damage_type: "piercing",
      weapon_properties: ["ammunition", "loading", "two-handed"],
      weight_pounds: 5,
      cost_gp: 25,
      is_magical: false,
      requires_attunement: false
    },
    # -------------------------------------------------------------------------
    # Martial Weapons
    # -------------------------------------------------------------------------
    "battleaxe" => %{
      name: "Battleaxe",
      item_type: :weapon,
      weapon_category: :martial,
      damage_dice: "1d8",
      damage_type: "slashing",
      weapon_properties: ["versatile"],
      weight_pounds: 4,
      cost_gp: 10,
      is_magical: false,
      requires_attunement: false
    },
    "greatsword" => %{
      name: "Greatsword",
      item_type: :weapon,
      weapon_category: :martial,
      damage_dice: "2d6",
      damage_type: "slashing",
      weapon_properties: ["heavy", "two-handed"],
      weight_pounds: 6,
      cost_gp: 50,
      is_magical: false,
      requires_attunement: false
    },
    "longsword" => %{
      name: "Longsword",
      item_type: :weapon,
      weapon_category: :martial,
      damage_dice: "1d8",
      damage_type: "slashing",
      weapon_properties: ["versatile"],
      weight_pounds: 3,
      cost_gp: 15,
      is_magical: false,
      requires_attunement: false
    },
    "rapier" => %{
      name: "Rapier",
      item_type: :weapon,
      weapon_category: :martial,
      damage_dice: "1d8",
      damage_type: "piercing",
      weapon_properties: ["finesse"],
      weight_pounds: 2,
      cost_gp: 25,
      is_magical: false,
      requires_attunement: false
    },
    "scimitar" => %{
      name: "Scimitar",
      item_type: :weapon,
      weapon_category: :martial,
      damage_dice: "1d6",
      damage_type: "slashing",
      weapon_properties: ["finesse", "light"],
      weight_pounds: 3,
      cost_gp: 25,
      is_magical: false,
      requires_attunement: false
    },
    "shortsword" => %{
      name: "Shortsword",
      item_type: :weapon,
      weapon_category: :martial,
      damage_dice: "1d6",
      damage_type: "piercing",
      weapon_properties: ["finesse", "light"],
      weight_pounds: 2,
      cost_gp: 10,
      is_magical: false,
      requires_attunement: false
    },
    # -------------------------------------------------------------------------
    # Armour
    # -------------------------------------------------------------------------
    "padded_armor" => %{
      name: "Padded Armor",
      item_type: :armor,
      armor_category: :light,
      base_ac: 11,
      stealth_disadvantage: true,
      strength_requirement: nil,
      weight_pounds: 8,
      cost_gp: 5,
      is_magical: false,
      requires_attunement: false
    },
    "leather_armor" => %{
      name: "Leather Armor",
      item_type: :armor,
      armor_category: :light,
      base_ac: 11,
      stealth_disadvantage: false,
      strength_requirement: nil,
      weight_pounds: 10,
      cost_gp: 10,
      is_magical: false,
      requires_attunement: false
    },
    "chain_shirt" => %{
      name: "Chain Shirt",
      item_type: :armor,
      armor_category: :medium,
      base_ac: 13,
      stealth_disadvantage: false,
      strength_requirement: nil,
      weight_pounds: 20,
      cost_gp: 50,
      is_magical: false,
      requires_attunement: false
    },
    "scale_mail" => %{
      name: "Scale Mail",
      item_type: :armor,
      armor_category: :medium,
      base_ac: 14,
      stealth_disadvantage: true,
      strength_requirement: nil,
      weight_pounds: 45,
      cost_gp: 50,
      is_magical: false,
      requires_attunement: false
    },
    "chain_mail" => %{
      name: "Chain Mail",
      item_type: :armor,
      armor_category: :heavy,
      base_ac: 16,
      stealth_disadvantage: true,
      strength_requirement: 13,
      weight_pounds: 55,
      cost_gp: 75,
      is_magical: false,
      requires_attunement: false
    },
    "plate_armor" => %{
      name: "Plate Armor",
      item_type: :armor,
      armor_category: :heavy,
      base_ac: 18,
      stealth_disadvantage: true,
      strength_requirement: 15,
      weight_pounds: 65,
      cost_gp: 1500,
      is_magical: false,
      requires_attunement: false
    },
    "shield" => %{
      name: "Shield",
      item_type: :armor,
      armor_category: :shield,
      base_ac: 2,
      stealth_disadvantage: false,
      strength_requirement: nil,
      weight_pounds: 6,
      cost_gp: 10,
      is_magical: false,
      requires_attunement: false
    },
    # -------------------------------------------------------------------------
    # Consumables
    # -------------------------------------------------------------------------
    "healing_potion" => %{
      name: "Potion of Healing",
      item_type: :consumable,
      charges: 1,
      effect_description: "Drink to regain 2d4+2 hit points.",
      weight_pounds: 0.5,
      cost_gp: 50,
      is_magical: true,
      requires_attunement: false
    },
    "greater_healing_potion" => %{
      name: "Potion of Greater Healing",
      item_type: :consumable,
      charges: 1,
      effect_description: "Drink to regain 4d4+4 hit points.",
      weight_pounds: 0.5,
      cost_gp: 150,
      is_magical: true,
      requires_attunement: false
    }
  }

  @doc "Returns all item definitions as a map keyed by string key, each with a `:modifiers` list."
  @spec all() :: %{String.t() => map()}
  def all, do: Map.new(@items, fn {key, item} -> {key, with_modifiers(item)} end)

  @doc "Returns the item definition (with its `:modifiers` list) for the given key, or nil."
  @spec get(String.t()) :: map() | nil
  def get(key) when is_binary(key) do
    case Map.get(@items, key) do
      nil -> nil
      item -> with_modifiers(item)
    end
  end

  defp with_modifiers(item), do: Map.put(item, :modifiers, modifiers_for(item))

  # Finesse weapons let the wielder choose DEX or STR for attack/damage ability.
  defp modifiers_for(%{item_type: :weapon, weapon_properties: props}) do
    if "finesse" in props do
      [
        %RuleModifier{
          id: :finesse_attack_choice,
          name: "Finesse",
          source: :equipped_weapon,
          trigger: {:on_attack, :melee},
          predicate: {:always},
          effect: {:choose_attack_ability, [:dexterity, :strength]},
          stacking: :binary_flag
        }
      ]
    else
      []
    end
  end

  # Shields add a flat AC bonus; body armour overrides the base AC formula.
  defp modifiers_for(%{item_type: :armor, armor_category: :shield, base_ac: bonus}) do
    [
      %RuleModifier{
        id: :shield_ac_bonus,
        name: "Shield",
        source: :equipped_armor,
        trigger: :passive,
        predicate: {:always},
        effect: {:add_bonus, :ac, bonus},
        stacking: :additive
      }
    ]
  end

  defp modifiers_for(%{item_type: :armor, armor_category: category, base_ac: base_ac}) do
    [
      %RuleModifier{
        id: :armor_class_formula,
        name: "Armor Class",
        source: :equipped_armor,
        trigger: :passive,
        predicate: {:always},
        effect: {:override_ac_formula, {:armor, category, base_ac}},
        stacking: :binary_flag
      }
    ]
  end

  defp modifiers_for(_item), do: []
end
