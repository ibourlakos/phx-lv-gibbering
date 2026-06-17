# #131 · Entity movement stats + `valid_moves` multi-mode deduction
**Status:** closed
**Opened:** 2026-06-13
**Closed:** 2026-06-17
**Priority:** medium
**Tags:** gameplay, rules

Extracted from Brainstorm #17 (movement model decisions). Extends entity stats with the four movement speed keys, updates `DnD5e.Stats` to derive from all four, and updates `action_economy.movement_remaining` to support mode-aware cost deduction. Depends on #130 (`GridTile.movement` JSONB).

**Acceptance criteria**
- [x] Entity `stats` JSONB: `"climb_speed"`, `"swim_speed"`, `"fly_speed"` keys added (integer | nil) alongside existing `"speed"` (walk)
- [x] Seeds and fixtures updated with movement speed keys for all seeded entities
- [x] `DnD5e.Stats` updated: `speed_for_mode/2` returns mode-specific speed (nil = entity can't use that mode)
- [x] `Rules.movement_cost_ft/2` computes tile foot cost from permission value (50% permission → ×2 ft, difficult terrain)
- [x] `Rules.valid_moves/3` accepts optional mode parameter; returns `[]` when entity has no speed for the requested mode
- [x] `DnD5e.advance_turn/1` and `initial_action_economy/1` apply passive speed-zeroing conditions to `movement_remaining` (Restrained, Grappled → 0)
- [x] `RuleModifier` entries updated: Restrained/Grappled use `{:set_all_speeds, 0}`; `:flying` condition grants `{:grant_speed, "fly", 60}`; `:spider_climb` condition grants `{:grant_speed, "climb", :equal_walk}`
- [x] `ModifierPipeline` handles `{:set_all_speeds, n}` and `{:grant_speed, mode, value}` effect types
- [x] All existing tests pass; 30 new tests in `test/engine/entity_movement_test.exs` cover multi-mode `valid_moves`, `movement_cost_ft`, `speed_for_mode`, condition speed zeroing, and Fly/Spider Climb condition definitions
