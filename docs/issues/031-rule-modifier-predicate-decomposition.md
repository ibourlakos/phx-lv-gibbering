# #31 · Trigger/predicate/effect decomposition for RuleModifier

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-05
**Priority:** high
**Tags:** discovery, rules, architecture

The Gibbering Engine needs a machine-readable representation of D&D 5e rules that the combat pipeline can evaluate without hardcoding class or race names. The working model is a three-part structure:

- **Trigger** — which engine event activates evaluation (`:on_attack_roll`, `:on_damage_received`, `:passive`, `:on_turn_start`, …)
- **Predicate** — a structured data expression (not a function) describing conditions that must hold for the effect to fire (`{:ally_adjacent_to_target}`, `{:entity_has_condition, :raging}`, `{:any_of, [p1, p2]}`, …)
- **Effect** — a tagged tuple describing the mutation to the resolution context (`{:add_damage_dice, "1d6"}`, `{:grant_advantage, :attack_rolls}`, `{:set_speed, 0}`, …)

## What needs to be decided

**Predicate vocabulary:** what is the full closed set of primitive predicate atoms required to express all SRD rules used by this engine? The evaluator is a recursive pattern-match function over this set — its complexity is bounded by the vocabulary size.

**Effect layering order:** effects must be applied in a defined order to produce correct results. The known layers are: immunity → resistance/vulnerability → flat bonuses (named vs additive) → dice modifiers → advantage/disadvantage (binary collapse). Does this ordering need to be explicit in the effect struct, or is it implied by effect type?

**Predicate context:** some predicates are entity-local (`:entity_has_condition`) and some require broader scene state (`:ally_adjacent_to_target`, `:first_attack_this_turn`). The last example requires turn history, making the event log a structural dependency of predicate evaluation — not just a nice-to-have feature.

**Named bonus non-stacking rule:** 5e specifies that two sources of the same named bonus don't stack (e.g. two Bless spells). How is this expressed? A `stacking: :named | :additive | :binary_flag` field on the effect? An explicit bonus name tag?

## Relation to other issues

- Directly required before `RuleModifier` can be implemented in code
- Predicate context dependency is an argument for the event log being part of `Engine.State` from the start (see #12)
- The closed predicate vocabulary is also the contract that DM overrides must respect (#32)
- Conditions become `ActiveEffect` entries whose `modifiers` are lists of `%RuleModifier{}` structs (#30)

**Acceptance criteria**
- [x] Full primitive predicate vocabulary enumerated and documented
- [x] Effect layering order documented
- [x] Stacking rule for named bonuses decided
- [x] `%RuleModifier{}` struct shape finalised (ready for implementation)

See [docs/architecture/predicate-vocabulary.md](../architecture/predicate-vocabulary.md) for the complete reference.
