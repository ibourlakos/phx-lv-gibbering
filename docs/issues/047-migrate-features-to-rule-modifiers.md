# #47 · Migrate `Data.Classes`/`Data.Races` features to `%RuleModifier{}`

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** rules

Class features and race traits are currently stored as inert `%{name: string, description: string}` maps. They have no mechanical effect — the engine never consults them. This issue replaces them with `%RuleModifier{}` structs so race and class features participate in the modifier pipeline.

Depends on #40 (RuleModifier struct and evaluator).

**Acceptance criteria**
- [ ] `Data.Classes` features list contains `%RuleModifier{}` structs (not plain maps) for all implemented classes (Fighter, Wizard, Rogue)
- [ ] `Data.Races` traits list contains `%RuleModifier{}` structs for all implemented races (Human, Elf, Gnome)
- [ ] At minimum: Rogue Sneak Attack, Barbarian Rage damage bonus, Fighter Second Wind, Elf Darkvision modelled as `%RuleModifier{}` with correct predicates and effects
- [ ] `collect_modifiers/3` returns race + class modifiers for a given trigger
- [ ] `mix precommit` passes
