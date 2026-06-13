# #130 · `GridTile.movement` JSONB — replace `walkable: boolean`
**Status:** open
**Opened:** 2026-06-13
**Priority:** medium
**Tags:** architecture, gameplay

Extracted from Brainstorm #17 (movement model decisions). Replace the binary `walkable` flag with a multi-mode `movement` JSONB that covers walk, climb, swim, and fly. Any entity occupying a tile can carry the same `stats["movement"]` shape; `valid_moves` merges tile and entity permissions using `min(tile, entity)` per mode. Absent key = blocked.

Values are integers 0–100 where 0 = blocked and 100 = full speed. Absent key = 0 (blocked).
Effective permission: `min(tile.movement[mode], min(entity.stats["movement"][mode] for each entity at (x,y)))`.

**Acceptance criteria**
- [ ] Migration: add `movement` JSONB column to `grid_tiles`, drop `walkable` boolean
- [ ] Backfill: previously walkable tiles → `%{"walk" => 100, "fly" => 100}`; previously non-walkable → `%{}`
- [ ] `%GridTile{}` struct updated: `movement: map()` replaces `walkable: boolean`
- [ ] `Engine.State` tile map shape updated accordingly (`movement: map` replaces `walkable: bool`)
- [ ] Seeds updated with explicit `movement` maps per terrain type
- [ ] `valid_moves` computation updated: filter tiles where `tile_movement_permission(state, x, y, "walk") > 0`; permission = `min(tile.movement[mode], min(entity.stats["movement"][mode])` for each entity at that coordinate
- [ ] Entity `stats["movement"]` absent entirely = entity does not constrain tile movement (e.g. decorative NPC, trap)
- [ ] Existing `walkable?` private helper removed; replaced by `tile_movement_permission/3` public function
- [ ] All existing tests pass; new unit tests cover the merge logic for all mode combinations
