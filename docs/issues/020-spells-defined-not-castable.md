# #20 · Spells are defined but not castable

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** medium
**Tags:** gameplay, rules

## Context

`Gibbering.Data.Spells` now defines cantrips and level-1 spells with full metadata (range, damage dice, attack type, school). Wizard characters have their spell list stored in `entity.stats["spells"]`. The lobby displays the spell tags on wizard cards.

However there is no mechanic to actually cast a spell. The game board shows only "End Turn" and melee attack actions. This closes the remaining scope of #2 (wizard first unique mechanic) once implemented.

## What needs to happen

1. **Action selection UI** — When a wizard is active, the side panel should offer spell buttons for each known spell (at minimum `fire_bolt` and `magic_missile`).
2. **Ranged targeting** — `fire_bolt` requires a ranged attack roll; `magic_missile` auto-hits. The Rules module needs `valid_spell_targets/3` that extends range beyond melee adjacency.
3. **Damage application** — Roll the spell's `damage_dice`, apply damage (possibly multi-target for AoE spells like `sleep`).
4. **Dice animation** — `push_event("roll_dice", ...)` should fire on spell cast, with the label showing the spell name.
5. **Spell slot tracking** — Level-1 spells are limited; cantrips are at-will. Track remaining slots in entity stats.

## Relationship to open issues

- Supersedes #2 (wizard first unique mechanic) — close #2 when this is implemented.
- Requires or motivates the Ruleset behaviour split (#14).

**Acceptance criteria**
- [x] Wizard can cast at least one cantrip (fire_bolt) from the game board
- [x] Ranged targeting overlay shown for spell range
- [x] Damage applied and dice animation plays on cast
- [x] Issue #2 closed
