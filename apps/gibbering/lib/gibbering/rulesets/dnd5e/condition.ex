defmodule Gibbering.Rulesets.DnD5e.Condition do
  @moduledoc """
  Static definitions for all 14 SRD conditions.

  Each `%Condition{}` carries a list of `%RuleModifier{}` structs expressing
  its mechanical effects. Modifiers are scoped by predicate:
  - `{:entity_has_condition, key}` — effect applies to the afflicted entity
  - `{:target_has_condition, key}` — effect applies to anyone targeting the entity

  `ModifierPipeline.collect_modifiers/3` merges both sets at resolution time,
  using `Enum.uniq_by/2` to prevent double-counting when both combatants share
  a condition.

  Conditions whose effect is action-economy suppression (Incapacitated, Paralyzed,
  Stunned, Petrified) have no roll modifiers here; the engine gates actions via
  the `{:entity_is_incapacitated}` predicate before any roll is attempted.
  """

  alias GibberingEngine.RuleModifier

  @enforce_keys [:id, :name]
  defstruct [:id, :name, :description, modifiers: []]

  @type t :: %__MODULE__{
          id: atom(),
          name: String.t(),
          description: String.t() | nil,
          modifiers: [RuleModifier.t()]
        }

  @doc "Returns all SRD conditions plus movement-granting conditions keyed by id."
  @spec all() :: %{atom() => t()}
  def all do
    %{
      blinded: %__MODULE__{
        id: :blinded,
        name: "Blinded",
        description:
          "Can't see. Attack rolls against you have advantage. Your attacks have disadvantage.",
        modifiers: [
          %RuleModifier{
            id: :blinded_dis_attacks,
            name: "Blinded: attack disadvantage",
            trigger: {:on_attack, :any},
            predicate: {:entity_has_condition, :blinded},
            effect: {:impose_disadvantage, :attack_rolls},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :blinded_adv_against,
            name: "Blinded: attackers gain advantage",
            trigger: {:on_attack, :any},
            predicate: {:target_has_condition, :blinded},
            effect: {:grant_advantage, :attack_rolls},
            stacking: :binary_flag
          }
        ]
      },
      charmed: %__MODULE__{
        id: :charmed,
        name: "Charmed",
        description:
          "Can't attack the charmer; charmer has advantage on Charisma checks against you.",
        # Social mechanics not in scope for the combat engine.
        modifiers: []
      },
      deafened: %__MODULE__{
        id: :deafened,
        name: "Deafened",
        description: "Can't hear; automatically fails hearing-based checks.",
        # No direct combat roll modifiers in SRD base rules.
        modifiers: []
      },
      exhaustion: %__MODULE__{
        id: :exhaustion,
        name: "Exhaustion",
        description: "Tiered debuff (levels 1–6) with escalating penalties.",
        # Full tiered implementation deferred; level tracking pending.
        modifiers: []
      },
      frightened: %__MODULE__{
        id: :frightened,
        name: "Frightened",
        description:
          "Disadvantage on attack rolls while source is visible; can't move toward source.",
        modifiers: [
          %RuleModifier{
            id: :frightened_dis_attacks,
            name: "Frightened: attack disadvantage",
            trigger: {:on_attack, :any},
            predicate: {:entity_has_condition, :frightened},
            effect: {:impose_disadvantage, :attack_rolls},
            stacking: :binary_flag
          }
        ]
      },
      grappled: %__MODULE__{
        id: :grappled,
        name: "Grappled",
        description: "Speed becomes 0.",
        modifiers: [
          %RuleModifier{
            id: :grappled_no_speed,
            name: "Grappled: speed 0",
            trigger: :passive,
            predicate: {:entity_has_condition, :grappled},
            effect: {:set_all_speeds, 0},
            stacking: :binary_flag
          }
        ]
      },
      incapacitated: %__MODULE__{
        id: :incapacitated,
        name: "Incapacitated",
        description: "Can't take actions or bonus actions.",
        # Enforced via {:entity_is_incapacitated} predicate at action-economy gating.
        modifiers: []
      },
      invisible: %__MODULE__{
        id: :invisible,
        name: "Invisible",
        description:
          "Impossible to see without special sense; attacks against have disadvantage, your attacks have advantage.",
        modifiers: [
          %RuleModifier{
            id: :invisible_adv_attacks,
            name: "Invisible: attack advantage",
            trigger: {:on_attack, :any},
            predicate: {:entity_has_condition, :invisible},
            effect: {:grant_advantage, :attack_rolls},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :invisible_dis_against,
            name: "Invisible: attackers suffer disadvantage",
            trigger: {:on_attack, :any},
            predicate: {:target_has_condition, :invisible},
            effect: {:impose_disadvantage, :attack_rolls},
            stacking: :binary_flag
          }
        ]
      },
      paralyzed: %__MODULE__{
        id: :paralyzed,
        name: "Paralyzed",
        description:
          "Incapacitated, can't move or speak; auto-fail STR/DEX saves; attacks have advantage; melee hits within 5 ft are critical hits.",
        modifiers: [
          %RuleModifier{
            id: :paralyzed_adv_against,
            name: "Paralyzed: attackers gain advantage",
            trigger: {:on_attack, :any},
            predicate: {:target_has_condition, :paralyzed},
            effect: {:grant_advantage, :attack_rolls},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :paralyzed_auto_crit,
            name: "Paralyzed: adjacent melee auto-crit",
            trigger: {:on_attack, :melee},
            predicate:
              {:all_of, [{:target_has_condition, :paralyzed}, {:entity_adjacent_to_target}]},
            effect: {:force_critical_hit},
            stacking: :binary_flag
          }
        ]
      },
      petrified: %__MODULE__{
        id: :petrified,
        name: "Petrified",
        description:
          "Turned to stone; incapacitated, resistance to all damage; attacks have advantage; adjacent melee hits are critical.",
        modifiers: [
          %RuleModifier{
            id: :petrified_resistance,
            name: "Petrified: resistance to all damage",
            trigger: {:on_damage_received, :any},
            predicate: {:entity_has_condition, :petrified},
            effect: {:grant_resistance, :all},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :petrified_adv_against,
            name: "Petrified: attackers gain advantage",
            trigger: {:on_attack, :any},
            predicate: {:target_has_condition, :petrified},
            effect: {:grant_advantage, :attack_rolls},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :petrified_auto_crit,
            name: "Petrified: adjacent melee auto-crit",
            trigger: {:on_attack, :melee},
            predicate:
              {:all_of, [{:target_has_condition, :petrified}, {:entity_adjacent_to_target}]},
            effect: {:force_critical_hit},
            stacking: :binary_flag
          }
        ]
      },
      poisoned: %__MODULE__{
        id: :poisoned,
        name: "Poisoned",
        description: "Disadvantage on attack rolls and ability checks.",
        modifiers: [
          %RuleModifier{
            id: :poisoned_dis_attacks,
            name: "Poisoned: attack disadvantage",
            trigger: {:on_attack, :any},
            predicate: {:entity_has_condition, :poisoned},
            effect: {:impose_disadvantage, :attack_rolls},
            stacking: :binary_flag
          }
        ]
      },
      prone: %__MODULE__{
        id: :prone,
        name: "Prone",
        description:
          "Disadvantage on attack rolls; melee attackers have advantage; ranged attackers have disadvantage.",
        modifiers: [
          %RuleModifier{
            id: :prone_dis_attacks,
            name: "Prone: attack disadvantage",
            trigger: {:on_attack, :any},
            predicate: {:entity_has_condition, :prone},
            effect: {:impose_disadvantage, :attack_rolls},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :prone_adv_melee,
            name: "Prone: melee attackers gain advantage",
            trigger: {:on_attack, :melee},
            predicate: {:target_has_condition, :prone},
            effect: {:grant_advantage, :attack_rolls},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :prone_dis_ranged,
            name: "Prone: ranged attackers suffer disadvantage",
            trigger: {:on_attack, :ranged},
            predicate: {:target_has_condition, :prone},
            effect: {:impose_disadvantage, :attack_rolls},
            stacking: :binary_flag
          }
        ]
      },
      restrained: %__MODULE__{
        id: :restrained,
        name: "Restrained",
        description:
          "Speed 0; disadvantage on attack rolls and DEX saves; attacks against have advantage.",
        modifiers: [
          %RuleModifier{
            id: :restrained_no_speed,
            name: "Restrained: speed 0",
            trigger: :passive,
            predicate: {:entity_has_condition, :restrained},
            effect: {:set_all_speeds, 0},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :restrained_dis_attacks,
            name: "Restrained: attack disadvantage",
            trigger: {:on_attack, :any},
            predicate: {:entity_has_condition, :restrained},
            effect: {:impose_disadvantage, :attack_rolls},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :restrained_adv_against,
            name: "Restrained: attackers gain advantage",
            trigger: {:on_attack, :any},
            predicate: {:target_has_condition, :restrained},
            effect: {:grant_advantage, :attack_rolls},
            stacking: :binary_flag
          },
          %RuleModifier{
            id: :restrained_dis_dex_saves,
            name: "Restrained: DEX save disadvantage",
            trigger: :passive,
            predicate:
              {:all_of,
               [{:entity_has_condition, :restrained}, {:saving_throw_ability_is, :dexterity}]},
            effect: {:impose_disadvantage, :saving_throws},
            stacking: :binary_flag
          }
        ]
      },
      stunned: %__MODULE__{
        id: :stunned,
        name: "Stunned",
        description:
          "Incapacitated, can't move; auto-fail STR/DEX saves; attacks against have advantage.",
        modifiers: [
          %RuleModifier{
            id: :stunned_adv_against,
            name: "Stunned: attackers gain advantage",
            trigger: {:on_attack, :any},
            predicate: {:target_has_condition, :stunned},
            effect: {:grant_advantage, :attack_rolls},
            stacking: :binary_flag
          }
        ]
      },

      # Movement-granting conditions (Fly spell, Spider Climb spell)
      flying: %__MODULE__{
        id: :flying,
        name: "Flying",
        description: "Magical flight (e.g. Fly spell). Grants a fly speed of 60 ft.",
        modifiers: [
          %RuleModifier{
            id: :flying_grant_fly_speed,
            name: "Flying: grant fly speed 60",
            trigger: :passive,
            predicate: {:entity_has_condition, :flying},
            effect: {:grant_speed, "fly", 60},
            stacking: :named_bonus
          }
        ]
      },
      spider_climb: %__MODULE__{
        id: :spider_climb,
        name: "Spider Climb",
        description:
          "Entity can climb difficult surfaces and ceilings. Grants climb speed equal to walk speed.",
        modifiers: [
          %RuleModifier{
            id: :spider_climb_grant_climb_speed,
            name: "Spider Climb: grant climb speed equal to walk",
            trigger: :passive,
            predicate: {:entity_has_condition, :spider_climb},
            effect: {:grant_speed, "climb", :equal_walk},
            stacking: :named_bonus
          }
        ]
      }
    }
  end

  @doc "Returns the condition definition for the given id, or nil."
  @spec get(atom()) :: t() | nil
  def get(id) when is_atom(id), do: Map.get(all(), id)
end
