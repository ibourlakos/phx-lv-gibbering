# #89 · Initial game content population — races, classes, starter monsters/items
**Status:** closed
**Opened:** 2026-06-06
**Closed:** 2026-06-07
**Priority:** low
**Tags:** gameplay, rules, admin

Populate the DB with an initial assortment of real game content following the workflow defined in #88:

- Races: at minimum the races available in BG3 (human, elf, half-elf, dwarf, halfling, tiefling, dragonborn, gnome, githyanki, half-orc) — SRD-legal subset first, BG3-exclusive handled separately
- Classes: all standard SRD classes (barbarian, bard, cleric, druid, fighter, monk, paladin, ranger, rogue, sorcerer, warlock, wizard)
- Monsters: an initial assortment drawn from SRD-legal sources; check #16 for legal constraints before committing any non-SRD content
- Items: a starter assortment (common weapons, armor, basic consumables) — SRD-legal sources only until #16 is resolved
- Character creation appearance enriched: body shape choices, token color palettes, style-appropriate defaults

**Acceptance criteria**
- [x] All BG3 SRD-legal races seeded with stats, traits, and at least a placeholder appearance record (9 races: human, elf, gnome, dwarf, half_elf, halfling, tiefling, dragonborn, half_orc)
- [x] All standard SRD classes seeded with starting equipment options, skill proficiency choices, and subclass list (12 classes)
- [x] ≥10 SRD-legal monsters seeded (12 monsters seeded in `Data.Monsters`)
- [ ] ≥20 SRD-legal items seeded — deferred to a future issue; items schema not yet defined
- [x] Character creation step surfaces all seeded races/classes
- [x] All seed data passes `mix test` with no regressions (652 tests, 0 failures)
- [x] Legal provenance confirmed for every piece of content added (SRD 5.1 CC-BY-4.0)
