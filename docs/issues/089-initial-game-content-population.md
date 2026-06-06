# #89 · Initial game content population — races, classes, starter monsters/items
**Status:** open
**Opened:** 2026-06-06
**Priority:** low
**Tags:** gameplay, rules, admin

Populate the DB with an initial assortment of real game content following the workflow defined in #88:

- Races: at minimum the races available in BG3 (human, elf, half-elf, dwarf, halfling, tiefling, dragonborn, gnome, githyanki, half-orc) — SRD-legal subset first, BG3-exclusive handled separately
- Classes: all standard SRD classes (barbarian, bard, cleric, druid, fighter, monk, paladin, ranger, rogue, sorcerer, warlock, wizard)
- Monsters: an initial assortment drawn from SRD-legal sources; check #16 for legal constraints before committing any non-SRD content
- Items: a starter assortment (common weapons, armor, basic consumables) — SRD-legal sources only until #16 is resolved
- Character creation appearance enriched: body shape choices, token color palettes, style-appropriate defaults

**Acceptance criteria**
- [ ] All BG3 SRD-legal races seeded with stats, traits, and at least a placeholder appearance record
- [ ] All standard SRD classes seeded with starting equipment options, skill proficiency choices, and subclass list
- [ ] ≥10 SRD-legal monsters seeded (used as combat encounter content for initial playtesting)
- [ ] ≥20 SRD-legal items seeded (weapons + armor + 2–3 consumables)
- [ ] Character creation step surfaces all seeded races/classes/backgrounds
- [ ] All seed data passes `mix test` with no regressions
- [ ] Legal provenance confirmed for every piece of content added
