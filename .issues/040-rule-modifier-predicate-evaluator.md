# #40 · `RuleModifier` struct + predicate evaluator + modifier pipeline

**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** rules, architecture

Implements the design settled in #31. No `%RuleModifier{}` struct or predicate
evaluator exists yet. All rules are hardcoded conditionals in `Rules`. This
issue replaces that with a data-driven modifier pipeline.

Depends on #39 (Ruleset behaviour shell). See [docs/predicate-vocabulary.md](../docs/predicate-vocabulary.md)
for the canonical predicate reference (51 predicates, 8 groups).

**Acceptance criteria**
- [ ] `%Gibbering.Rulesets.DnD5e.RuleModifier{}` struct defined: `[:id, :name, :description, :source, :trigger, :predicate, :effect, stacking: :additive, min_level: 1]`
- [ ] `Predicate.eval/2` implemented for all 51 predicates in the vocabulary; returns `boolean()`
- [ ] Group 7 predicates evaluate `true` outside `:in_combat` phase
- [ ] Group 6 predicates evaluate `false` when `resolution` is `nil`
- [ ] `collect_modifiers(entity, trigger, context)` returns `[%RuleModifier{}]` from race traits + class features + active conditions
- [ ] `apply_modifiers(roll_context, modifiers)` folds effects in correct layering order: immunity → resistance → named bonuses (highest wins) → additive → dice → advantage/disadvantage
- [ ] `stacking: :named_bonus` — only highest-value modifier of same id applies
- [ ] Unit tests cover all 8 predicate groups with representative cases
- [ ] Unit tests cover modifier stacking rules for all three stacking modes
- [ ] `mix precommit` passes
