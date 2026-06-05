# #40 · `RuleModifier` struct + predicate evaluator + modifier pipeline

**Status:** closed
**Closed:** 2026-06-05
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** rules, architecture

Implements the design settled in #31. No `%RuleModifier{}` struct or predicate
evaluator exists yet. All rules are hardcoded conditionals in `Rules`. This
issue replaces that with a data-driven modifier pipeline.

Depends on #39 (Ruleset behaviour shell). See [docs/predicate-vocabulary.md](../docs/predicate-vocabulary.md)
for the canonical predicate reference (51 predicates, 8 groups).

**Acceptance criteria**
- [x] `%Gibbering.Rulesets.DnD5e.RuleModifier{}` struct defined: `[:id, :name, :description, :source, :trigger, :predicate, :effect, stacking: :additive, min_level: 1]`
- [x] `Predicate.eval/2` implemented for all 51 predicates in the vocabulary; returns `boolean()`
- [x] Group 7 predicates evaluate `true` outside `:in_combat` phase
- [x] Group 6 predicates evaluate `false` when `resolution` is `nil`
- [x] `collect_modifiers(entity, trigger, context)` returns `[%RuleModifier{}]` from race traits + class features + active conditions
- [x] `apply_modifiers(roll_context, modifiers)` folds effects in correct layering order: immunity → resistance → named bonuses (highest wins) → additive → dice → advantage/disadvantage
- [x] `stacking: :named_bonus` — only highest-value modifier of same id applies
- [x] Unit tests cover all 8 predicate groups with representative cases
- [x] Unit tests cover modifier stacking rules for all three stacking modes
- [x] `mix precommit` passes
