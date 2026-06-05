# #42 · `Condition` struct + runtime application via active effects registry

**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** rules, gameplay

No `%Condition{}` struct exists and conditions cannot be applied to entities.
This issue adds the static condition definitions and the runtime machinery to
apply/remove them through the scene `active_effects` registry.

Depends on #40 (RuleModifier struct and predicate evaluator).
Also closes #30 (conditions and status effects engine model).

**Acceptance criteria**
- [ ] `%Gibbering.Rulesets.DnD5e.Condition{}` struct defined: `[:id, :name, :description, :modifiers]` where `modifiers: [%RuleModifier{}]`
- [ ] All 14 SRD conditions defined: Blinded, Charmed, Deafened, Exhaustion, Frightened, Grappled, Incapacitated, Invisible, Paralyzed, Petrified, Poisoned, Prone, Restrained, Stunned
- [ ] `apply_condition(state, entity_id, condition_id, opts)` adds an `ActiveEffect` entry to `state.active_effects` with correct source, duration, and modifiers
- [ ] `remove_condition(state, entity_id, condition_id)` removes the matching entry from the registry
- [ ] Predicate `{:entity_has_condition, key}` resolves correctly against the registry
- [ ] Issue #30 closed
- [ ] `mix precommit` passes
