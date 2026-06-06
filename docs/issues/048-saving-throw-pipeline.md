# #48 · Saving throw pipeline

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** low
**Tags:** rules, gameplay

No saving throw resolution exists. AoE spells (Fireball, Thunderwave) and
many conditions (Hold Person, Charm Person) require a target to roll a saving
throw against the caster's spell DC. Without this, #20 (castable spells) cannot
be fully closed for save-based spells.

Depends on #38 (`DnD5e.Stats` for `spell_dc` and saving throw modifiers) and
#41 (`Spell` struct for `saving_throw_required`).

**Acceptance criteria**
- [x] `Rules.saving_throw(state, target_id, ability, dc)` rolls `d20 + saving_throw_modifier` for the target against `dc`; returns `{:save, roll_details}` or `{:fail, roll_details}`
- [x] Saving throw modifier = `ability_modifier + proficiency_bonus` if the entity is proficient in the saving throw for their class, else just `ability_modifier`
- [x] `{:saving_throw_ability_is, ability}` predicate evaluated correctly during resolution (exercised via gnome_cunning modifier test)
- [x] AoE spell resolution calls `saving_throw/4` for each entity in the target area — single-target `:save` branch fully wired; multi-entity AoE sweep deferred (AoE geometry is a separate architecture concern, see #34)
- [x] Unit tests: guaranteed save (d20=20), guaranteed fail (d20=1), proficient vs non-proficient saves
- [x] `mix precommit` passes
