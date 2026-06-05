# #48 · Saving throw pipeline

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** rules, gameplay

No saving throw resolution exists. AoE spells (Fireball, Thunderwave) and
many conditions (Hold Person, Charm Person) require a target to roll a saving
throw against the caster's spell DC. Without this, #20 (castable spells) cannot
be fully closed for save-based spells.

Depends on #38 (`DnD5e.Stats` for `spell_dc` and saving throw modifiers) and
#41 (`Spell` struct for `saving_throw_required`).

**Acceptance criteria**
- [ ] `Rules.saving_throw(state, target_id, ability, dc)` rolls `d20 + saving_throw_modifier` for the target against `dc`; returns `{:save, roll_details}` or `{:fail, roll_details}`
- [ ] Saving throw modifier = `ability_modifier + proficiency_bonus` if the entity is proficient in the saving throw for their class, else just `ability_modifier`
- [ ] `{:saving_throw_ability_is, ability}` predicate evaluated correctly during resolution
- [ ] AoE spell resolution calls `saving_throw/4` for each entity in the target area
- [ ] Unit tests: guaranteed save (d20=20), guaranteed fail (d20=1), proficient vs non-proficient saves
- [ ] `mix precommit` passes
