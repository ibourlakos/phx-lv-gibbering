# #130 · `GridTile.movement` JSONB — replace `walkable: boolean`
**Status:** open
**Opened:** 2026-06-13
**Priority:** medium
**Tags:** architecture, gameplay

Extracted from Brainstorm #17 (movement model decisions). Replace the binary `walkable` flag with a multi-mode `movement` JSONB that covers walk, climb, swim, and fly. Any entity occupying a tile can carry the same `stats["movement"]` shape; `valid_moves` merges tile and entity permissions using `min(tile, entity)` per mode. Absent key = blocked.

**Acceptance criteria**
- [ ] Migration: add `movement` JSONB column to `grid_tiles`, drop `walkable` boolean
- [ ] Backfill: previously walkable tiles → `%{"walk" => "normal", "fly" => "normal"}`; previously non-walkable → `%{}`
- [ ] `%GridTile{}` struct updated: `movement: map()` replaces `walkable: boolean`
- [ ] `Engine.State` tile map shape updated accordingly
- [ ] Seeds updated with explicit `movement` maps per terrain type
- [ ] `valid_moves` computation updated: merge `tile.movement` with all entity `stats["movement"]` at the same coordinate, per mode; absent key treated as `"blocked"`; `"difficult"` costs ×2 movement
- [ ] Entity `stats["movement"]` absent entirely = entity does not constrain tile movement (e.g. decorative NPC, trap)
- [ ] Existing `tile_walkable?` helper removed or replaced
- [ ] All existing tests pass; new unit tests cover the merge logic for all mode combinations
