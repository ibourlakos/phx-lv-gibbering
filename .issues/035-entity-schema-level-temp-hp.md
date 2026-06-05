# #35 · Entity schema: add `level`, `temp_hp`, `challenge_rating`, `xp_reward`

**Status:** open
**Opened:** 2026-06-05
**Priority:** high
**Tags:** architecture, rules

The `entities` table stores all actors but lacks columns required for D&D 5e
rules: level (drives proficiency bonus, spell slots, feature unlocks), temp HP
(separate pool above max HP), and monster-specific CR/XP. Without these,
`DnD5e.Stats` (#38) cannot compute correct derived values.

**Acceptance criteria**
- [ ] Migration adds `level integer NOT NULL DEFAULT 1`, `temp_hp integer NOT NULL DEFAULT 0`, `challenge_rating numeric` (nullable), `xp_reward integer` (nullable) to `entities`
- [ ] `Gibbering.Entity` Ecto schema updated with the four new fields
- [ ] Seeds updated so existing hero entities get `level: 1` and monster entities get representative `challenge_rating`/`xp_reward` values
- [ ] `mix precommit` passes
