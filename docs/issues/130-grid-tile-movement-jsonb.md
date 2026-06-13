# #130 · `GridTile.movement` JSONB — replace `walkable: boolean`
**Status:** closed
**Opened:** 2026-06-13
**Closed:** 2026-06-14
**Priority:** medium
**Tags:** architecture, gameplay

Extracted from Brainstorm #17 (movement model decisions). Replace the binary `walkable` flag with a multi-mode `movement` JSONB that covers walk, climb, swim, and fly. Any entity occupying a tile can carry the same `stats["movement"]` shape; `valid_moves` merges tile and entity permissions using `min(tile, entity)` per mode. Absent key = blocked.

Values are integers 0–100 where 0 = blocked and 100 = full speed. Absent key = 0 (blocked).
Effective permission: `min(tile.movement[mode], min(entity.stats["movement"][mode] for each entity at (x,y)))`.

**Acceptance criteria**
- [x] Migration: add `movement` JSONB column to `grid_tiles`, drop `walkable` boolean
- [x] Backfill: previously walkable tiles → `%{"walk" => 100, "fly" => 100}`; previously non-walkable → `%{}`
- [x] `%GridTile{}` struct updated: `movement: map()` replaces `walkable: boolean`
- [x] `Engine.State` tile map shape updated accordingly (`movement: map` replaces `walkable: bool`)
- [x] Seeds updated with explicit `movement` maps per terrain type
- [x] `valid_moves` computation updated: filter tiles where `tile_movement_permission(state, x, y, "walk") > 0`; permission = `min(tile.movement[mode], min(entity.stats["movement"][mode])` for each entity at that coordinate
- [x] Entity `stats["movement"]` absent entirely = entity does not constrain tile movement (e.g. decorative NPC, trap)
- [x] Existing `walkable?` private helper removed; replaced by `tile_movement_permission/3` public function
- [x] All existing tests pass; new unit tests cover the merge logic for all mode combinations
