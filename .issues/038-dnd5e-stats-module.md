# #38 · `DnD5e.Stats`: derived stat computation module

**Status:** open
**Opened:** 2026-06-05
**Priority:** high
**Tags:** rules, architecture

No module currently computes D&D 5e derived stats. `Rules.attack/3` rolls a
bare 1d6 because it has no access to attack bonus or target AC. This issue
creates the pure-function module that all rules-engine consumers will call.

Depends on #35 (`level` column on entities).

**Acceptance criteria**
- [ ] `Gibbering.Rulesets.DnD5e.Stats` module created with pure functions (no DB, no process, no side effects)
- [ ] `ability_modifier(score)` returns `floor((score - 10) / 2)` — correct for all scores 1–30
- [ ] `proficiency_bonus(level)` returns 2 at L1, 3 at L5, 4 at L9, 5 at L13, 6 at L17
- [ ] `armor_class(entity)` reads `stats["equipped_armor"]["base_ac"]`; falls back to `10 + dex_modifier`
- [ ] `attack_bonus(entity, :melee)` returns `proficiency_bonus + str_modifier`; `attack_bonus(entity, :ranged)` uses `dex`; `attack_bonus(entity, :spell)` uses spellcasting ability for entity class
- [ ] `spell_dc(entity)` returns `8 + proficiency_bonus + spellcasting_modifier`
- [ ] `State.from_campaign/1` uses `Stats` to pre-compute and store `ability_modifiers`, `proficiency_bonus`, `armor_class` on each runtime entity map
- [ ] Unit tests at the pure-function layer cover all edge cases (score 1, score 30, level 1, level 20)
- [ ] `mix precommit` passes
