# #47 · Migrate `Data.Classes`/`Data.Races` features to `%RuleModifier{}`

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** low
**Tags:** rules

Class features and race traits are currently stored as inert `%{name: string, description: string}` maps. They have no mechanical effect — the engine never consults them. This issue replaces them with `%RuleModifier{}` structs so race and class features participate in the modifier pipeline.

Depends on #40 (RuleModifier struct and evaluator).

**Acceptance criteria**
- [x] `Data.Classes` features list contains `%RuleModifier{}` structs (not plain maps) for all implemented classes (Fighter, Wizard, Rogue) — via `Data.Classes.modifiers/1`; wizard's combat features are in the spellcasting system (`spell_attack_bonus`, `spell_dc`) rather than the modifier pipeline
- [x] `Data.Races` traits list contains `%RuleModifier{}` structs for all implemented races (Human, Elf, Gnome) — via `Data.Races.modifiers/1`
- [x] At minimum: Rogue Sneak Attack, Barbarian Rage damage bonus, Fighter Second Wind, Elf Darkvision modelled as `%RuleModifier{}` with correct predicates and effects
- [x] `collect_modifiers/3` returns race + class modifiers for a given trigger
- [x] `mix precommit` passes
