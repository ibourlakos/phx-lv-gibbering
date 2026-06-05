# #41 · `Spell` struct completion + `Data.Spells` migration

**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** rules, gameplay

`Data.Spells` returns flat string maps. The engine needs structured `%Spell{}`
values with typed fields to drive targeting overlays, slot consumption, and
concentration tracking. Enables #20 (castable spells).

**Acceptance criteria**
- [ ] `%Gibbering.Rulesets.DnD5e.Spell{}` struct defined with fields: `[:key, :name, :level, :school, :casting_time, :range, :components, :duration, :target_area, :effect, :tags]` — shapes per `docs/data-model.md`
- [ ] `Data.Spells` migrated to return `%Spell{}` structs (all existing spell keys preserved)
- [ ] `casting_time` is a tagged tuple: `{:action} | {:bonus_action} | {:reaction, trigger_pred} | {:minutes, n}`
- [ ] `duration.is_concentration` boolean present on all spells
- [ ] `target_area.shape` atom present on all spells
- [ ] All callers of `Data.Spells` updated
- [ ] `mix precommit` passes
