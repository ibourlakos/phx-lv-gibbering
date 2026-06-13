# #131 · Entity movement stats + `valid_moves` multi-mode deduction
**Status:** open
**Opened:** 2026-06-13
**Priority:** medium
**Tags:** gameplay, rules

Extracted from Brainstorm #17 (movement model decisions). Extends entity stats with the four movement speed keys, updates `DnD5e.Stats` to derive from all four, and updates `action_economy.movement_remaining` to support mode-aware cost deduction. Depends on #130 (`GridTile.movement` JSONB).

**Acceptance criteria**
- [ ] Entity `stats` JSONB: `"climb_speed"`, `"swim_speed"`, `"fly_speed"` keys added (integer | nil) alongside existing `"speed"` (walk)
- [ ] Seeds and fixtures updated with movement speed keys for all seeded entities
- [ ] `DnD5e.Stats` (#38) updated to compute derived stats from all four speed keys
- [ ] `action_economy.movement_remaining` (#37 model) supports mode-aware cost deduction: `"difficult"` terrain costs ×2; `"blocked"` mode = 0 remaining regardless of speed
- [ ] `RuleModifier` entries that affect movement (Fly spell grants `fly_speed`; Restrained sets all movement to 0; Spider Climb grants `climb: "normal"` regardless of tile) target the correct stats keys
- [ ] All existing tests pass; new tests cover multi-mode deduction for common D&D 5e movement scenarios
