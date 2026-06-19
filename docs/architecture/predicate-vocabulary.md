# Predicate Vocabulary

The `RuleModifier` struct's `:predicate` field is a closed-vocabulary expression
evaluated by a single recursive pattern-match function. This document is the
canonical reference for that vocabulary.

Related issues: [#31](../issues/031-rule-modifier-predicate-decomposition.md)
(implementation), [#32](../issues/032-dm-override-event-schema.md) (DM overrides
must compose with this pipeline, not bypass it).

---

## Evaluator Contract

```elixir
@spec eval(predicate(), eval_context()) :: boolean()
```

```elixir
@type eval_context :: %{
  entity:     entity_map(),           # actor whose modifier is being evaluated
  target:     entity_map() | nil,     # action target (nil for passive effects)
  scene:      scene_context(),
  resolution: resolution_context() | nil  # only set during active action resolution
}

@type scene_context :: %{
  entities:       %{integer() => entity_map()},
  grid:           %{{integer(), integer()} => tile_map()},
  active_effects: [active_effect()],
  event_log:      [event()],
  phase:          scene_phase()
}

@type resolution_context :: %{
  attack_type:          :melee | :ranged | :ranged_spell | :melee_spell | nil,
  damage_type:          atom() | nil,
  is_critical:          boolean(),
  economy_slot:         :action | :bonus_action | :reaction | nil,
  weapon:               weapon_map() | nil,
  spell:                spell_struct() | nil,
  saving_throw_ability: atom() | nil
}

@type scene_phase :: :lobby | :exploration | :initiative_rolling | :in_combat | :paused
```

**Phase semantics for Group 7 predicates (turn history):** outside `:in_combat`
there is no formal turn structure. Group 7 predicates evaluate to `true` by default
in any other phase — conservative, never denies a mechanic on a technicality.

**Resolution-context predicates (Group 6):** evaluate to `false` when
`resolution` is `nil` (i.e. outside an active action resolution).

---

## `%RuleModifier{}` Struct

```elixir
defstruct [
  :id,        # atom — unique identifier, e.g. :sneak_attack
  :name,      # string — human-readable label
  :trigger,   # see Trigger Vocabulary below
  :predicate, # see Predicate Vocabulary below
  :effect,    # see Effect Vocabulary below
  stacking: :additive   # :additive | :named_bonus | :binary_flag
]
```

### Trigger Vocabulary

| Trigger | Fires when |
|---|---|
| `{:on_attack, :melee \| :ranged \| :ranged_spell \| :melee_spell \| :any}` | entity makes an attack of the given type |
| `:on_being_attacked` | entity is the target of an attack |
| `{:on_damage_received, damage_type \| :any}` | entity takes damage of the given type |
| `:on_turn_start` | start of this entity's turn |
| `:on_saving_throw` | entity makes a saving throw |
| `:passive` | re-evaluated on every pipeline pass; always active while predicate holds |

### Effect Vocabulary

| Effect | Meaning |
|---|---|
| `{:add_damage_dice, dice_string, name_key}` | roll additional dice and add to damage; e.g. `{:add_damage_dice, "1d6", :sneak_attack}` |
| `{:add_bonus, :damage \| :attack \| :save \| :ac, integer}` | flat integer bonus to damage, attack roll, saving throw, or armour class (`:ac` from shields) |
| `{:choose_attack_ability, [ability]}` | wielder may pick the best of the listed abilities for attack/damage (finesse weapons) — collected by the pipeline; AC math still flows through `DnD5e.Stats` (issue #128, transitional) |
| `{:override_ac_formula, {:armor, category, base_ac}}` | equipped body armour replaces the base AC formula — collected by the pipeline; AC math still flows through `DnD5e.Stats` (issue #128, transitional) |
| `{:add_to_roll, dice_string}` | roll additional dice and add to the triggering d20 roll (Bless) |
| `{:grant_advantage, :attack_rolls \| :saving_throws \| :ability_checks}` | entity has advantage on rolls of this type |
| `{:impose_disadvantage, :attack_rolls \| :saving_throws \| :ability_checks}` | entity has disadvantage |
| `{:grant_resistance, damage_type \| :all}` | halve damage of this type |
| `{:grant_immunity, damage_type \| :all}` | negate damage of this type |
| `{:force_critical_hit}` | attack against this entity is treated as a critical hit |
| `{:set_speed, integer}` | override entity speed (e.g. `0` for paralysis) |
| `{:apply_condition, condition_key}` | add a condition to the entity |

---

## Group 1 — Structural Combinators

No context fields required.

| Predicate | Meaning |
|---|---|
| `{:always}` | unconditionally `true` — for passive always-on effects |
| `{:never}` | unconditionally `false` — for disabled or reserved rules |
| `{:all_of, [pred]}` | logical AND — short-circuits on first `false` |
| `{:any_of, [pred]}` | logical OR — short-circuits on first `true` |
| `{:not, pred}` | logical NOT |

---

## Group 2 — Entity-Local

Reads only `context.entity`. No scene or resolution access needed.

| Predicate | Meaning |
|---|---|
| `{:entity_type_is, :hero \| :monster \| :object}` | matches `entity.type` |
| `{:entity_class_is, class_atom}` | matches `entity.class` |
| `{:entity_race_is, race_atom}` | matches `entity.race` |
| `{:entity_level_gte, n}` | `entity.level >= n` |
| `{:entity_has_tag, tag}` | `tag ∈ entity.tags` |
| `{:entity_hp_lte_fraction, :half \| :quarter}` | `entity.hp / entity.max_hp <= fraction` |
| `{:entity_has_resource, resource_key}` | `entity.resources[key] >= 1` |
| `{:entity_resource_gte, resource_key, n}` | `entity.resources[key] >= n` |
| `{:entity_wielding_property, property}` | equipped weapon has this property (`:finesse \| :reach \| :heavy \| :light \| :two_handed \| :ranged`) |
| `{:entity_armor_category, category}` | equipped armor category (`:none \| :light \| :medium \| :heavy`) |

---

## Group 3 — Entity Conditions

Reads `context.entity` + `context.scene.active_effects`.

| Predicate | Meaning |
|---|---|
| `{:entity_has_condition, condition_key}` | entity has this condition in the effects registry |
| `{:entity_concentrating_on, spell_key \| :any}` | entity has a concentration effect; `:any` matches any spell |
| `{:entity_is_incapacitated}` | convenience — covers all conditions that impose incapacitated |

---

## Group 4 — Target State

Reads `context.target` + `context.scene.active_effects`.

| Predicate | Meaning |
|---|---|
| `{:target_has_condition, condition_key}` | target has this condition in the effects registry |
| `{:target_type_is, :hero \| :monster \| :object}` | matches `target.type` |
| `{:target_has_tag, tag}` | `tag ∈ target.tags` |
| `{:target_hp_lte_fraction, :half \| :quarter}` | `target.hp / target.max_hp <= fraction` |
| `{:target_is_incapacitated}` | convenience — any incapacitating condition on target |
| `{:target_is_creature}` | target type is `:hero` or `:monster` (not `:object`) |

---

## Group 5 — Spatial

Reads `context.entity`, `context.target`, `context.scene.entities`, `context.scene.grid`.
Distance uses Chebyshev (5e diagonal = 5 ft, matching issue #7).

| Predicate | Meaning |
|---|---|
| `{:entity_adjacent_to_target}` | entity within 5 ft (1 tile Chebyshev) of target |
| `{:ally_adjacent_to_target}` | any ally of entity within 5 ft of target |
| `{:no_enemy_adjacent_to_entity}` | no hostile within 5 ft of entity |
| `{:target_within_range, n_feet}` | target position within `n_feet` of entity |
| `{:entity_has_cover_from_target}` | entity has half or three-quarters cover vs target LoS |
| `{:target_has_cover_from_entity}` | target has cover vs entity LoS |
| `{:entity_and_ally_flank_target}` | entity and an ally are on opposite sides of target (optional flanking rule) |
| `{:entity_tile_has_tag, tile_tag}` | tile entity stands on has this tag (`:difficult_terrain \| :elevated \| :water`) |

---

## Group 6 — Resolution Context

Reads `context.resolution`. Evaluates to `false` when `resolution` is `nil`.
These predicates are only meaningful during an active action resolution (attack, spell, saving throw).

| Predicate | Meaning |
|---|---|
| `{:attack_type_is, type}` | `resolution.attack_type` is `:melee \| :ranged \| :ranged_spell \| :melee_spell` |
| `{:damage_type_is, damage_type}` | `resolution.damage_type` matches |
| `{:is_critical_hit}` | `resolution.is_critical == true` |
| `{:weapon_has_property, property}` | `resolution.weapon` has this property |
| `{:spell_school_is, school}` | `resolution.spell.school` matches |
| `{:spell_level_gte, n}` | `resolution.spell.level >= n` (upcast detection) |
| `{:saving_throw_ability_is, ability}` | `resolution.saving_throw_ability` matches |
| `{:is_bonus_action_attack}` | `resolution.economy_slot == :bonus_action` |
| `{:first_attack_in_resolution}` | first attack object in a multi-attack resolution context |

---

## Group 7 — Turn History

Reads `context.scene.event_log`. This is the group that makes the event log a
**structural dependency** of predicate evaluation — not an optional feature.
Outside `:in_combat`, all Group 7 predicates evaluate to `true` (see phase semantics above).

| Predicate | Meaning |
|---|---|
| `{:first_attack_this_turn}` | no `:attack_rolled` event for this entity in the current turn |
| `{:has_moved_this_turn}` | `:entity_moved` event exists for this entity this turn |
| `{:has_used_action_this_turn}` | `:action_used` event for this entity this turn |
| `{:has_used_bonus_action_this_turn}` | `:bonus_action_used` event for this entity this turn |
| `{:took_damage_this_turn}` | `:damage_received` event for this entity this turn |
| `{:took_damage_type_this_turn, damage_type}` | `:damage_received` event with matching damage type |
| `{:entity_was_attacked_this_round}` | `:attack_targeted` event with this entity as target this round |
| `{:round_number_gte, n}` | combat round counter `>= n` |

---

## Group 8 — Scene State

Reads `context.scene`.

| Predicate | Meaning |
|---|---|
| `{:scene_phase_is, phase}` | `scene.phase` matches — for effects scoped to a phase |
| `{:entity_has_active_effect, effect_key}` | direct registry query by key, bypasses condition sugar |
| `{:effect_source_is, source}` | source of the triggering effect (`:dm \| :spell \| :class_feature \| :item`) |

---

## Composed Examples

These four SRD rules expressed as `%RuleModifier{}` predicates. They show how
the vocabulary composes for real mechanics.

### Sneak Attack (Rogue)

Extra 1d6 damage per Rogue level on the first qualifying attack each turn.

```elixir
%RuleModifier{
  id: :sneak_attack,
  name: "Sneak Attack",
  trigger: {:on_attack, :any},
  predicate: {:all_of, [
    {:entity_class_is, :rogue},
    {:first_attack_this_turn},
    {:attack_type_is, :ranged},   # or melee with finesse — outer any_of
    {:any_of, [
      {:ally_adjacent_to_target},
      {:target_has_condition, :disadvantaged_on_attack}
    ]},
    {:not, {:entity_has_condition, :disadvantaged_on_attack}}
  ]},
  effect: {:add_damage_dice, "1d6", :sneak_attack},
  stacking: :named_bonus
}
```

### Rage Damage Bonus (Barbarian)

+2 damage on Strength-based melee attacks while Raging.

```elixir
%RuleModifier{
  id: :rage_damage_bonus,
  name: "Rage — Damage",
  trigger: {:on_attack, :melee},
  predicate: {:all_of, [
    {:entity_class_is, :barbarian},
    {:entity_has_condition, :raging},
    {:attack_type_is, :melee},
    {:not, {:entity_wielding_property, :ranged}}
  ]},
  effect: {:add_bonus, :damage, 2},
  stacking: :named_bonus
}
```

### Paralyzed — Auto-Crit at Melee Range

Melee attacks against a Paralyzed creature within 5 ft are automatically critical hits.

```elixir
%RuleModifier{
  id: :paralyzed_auto_crit,
  name: "Paralyzed — Auto-Crit",
  trigger: :on_being_attacked,
  predicate: {:all_of, [
    {:entity_has_condition, :paralyzed},
    {:attack_type_is, :melee},
    {:entity_adjacent_to_target}   # target is self here; entity is attacker
  ]},
  effect: {:force_critical_hit},
  stacking: :binary_flag
}
```

### Rage Damage Resistance

While Raging, resistance to Bludgeoning, Piercing, and Slashing damage.

```elixir
%RuleModifier{
  id: :rage_resistance,
  name: "Rage — Resistance",
  trigger: {:on_damage_received, :any},
  predicate: {:all_of, [
    {:entity_class_is, :barbarian},
    {:entity_has_condition, :raging},
    {:damage_type_is_one_of, [:bludgeoning, :piercing, :slashing]}
  ]},
  effect: {:grant_resistance},
  stacking: :binary_flag
}
```

> Note: `{:damage_type_is_one_of, list}` is sugar for `{:any_of, Enum.map(list, &{:damage_type_is, &1})}`.
> It may be added as a Group 6 convenience predicate when implementing #40.

---

## Effect Stacking Rules

Every `%RuleModifier{}` carries a `stacking` field:

| Mode | Behaviour |
|---|---|
| `:additive` | stack freely — sum all matching bonuses |
| `:named_bonus` | only the highest value applies — two Bless spells do not stack |
| `:binary_flag` | advantage/disadvantage, resistance — presence/absence only; multiple sources don't multiply |

Layering order during resolution: immunity → resistance/vulnerability → named bonuses (highest wins) → additive flat bonuses → dice modifiers → advantage/disadvantage collapse.
