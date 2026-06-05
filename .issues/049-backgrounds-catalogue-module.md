# #49 · Backgrounds catalogue module
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-05
**Priority:** high
**Tags:** rules, gameplay

Add `Gibbering.Data.Backgrounds` — a static in-memory module parallel to `Data.Races` and `Data.Classes`. Each background grants skill proficiencies, optional tool proficiencies, language slots, a starting equipment list, a narrative feature, and personality suggestions (traits, ideals, bonds, flaws).

Cover all SRD-legal backgrounds: Acolyte, Criminal, Folk Hero, Guild Artisan, Hermit, Noble, Outlander, Sage, Sailor, Soldier, Urchin.

When a background is selected during character creation, its proficiencies merge with class proficiencies. Duplicate proficiencies give the player a free replacement pick (standard 5e rule).

**Acceptance criteria**
- [ ] `Gibbering.Data.Backgrounds` module exists with all SRD backgrounds
- [ ] Each entry includes: `skill_proficiencies`, `tool_proficiencies`, `languages` (count), `starting_equipment`, `feature` (`name` + `description`), `suggested_traits`, `suggested_ideals`, `suggested_bonds`, `suggested_flaws`
- [ ] `Gibbering.Data.Backgrounds.get/1` returns a background by key string
- [ ] `Gibbering.Data.Backgrounds.all/0` returns the full list
- [ ] All content is SRD-legal — verified against `docs/legal.md`
