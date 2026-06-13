# #129 · Phase 1: introduce `maps` table
**Status:** open
**Opened:** 2026-06-13
**Priority:** medium
**Tags:** architecture, ops

Extracted from Brainstorm #17 (BS-17 Q3, Q4, Q8, Q9 decisions). Phase 1 of the campaign/scene/map restructure: introduce a `maps` table between `campaigns` and `grid_tiles`, move geometry out of `campaigns`, and wire `SceneServer` to load maps by `map_id`.

**Acceptance criteria**
- [ ] New `maps` table: `id`, `campaign_id` FK, `x_extent` integer, `y_extent` integer, `tile_size` integer, timestamps
- [ ] `campaigns` table: `map_width`, `map_height`, `tile_size` columns removed; `active_map_id` FK added
- [ ] `grid_tiles.campaign_id` FK changed to `grid_tiles.map_id`
- [ ] Seeds updated: each seeded campaign creates a corresponding `maps` record
- [ ] `Engine.State` carries `map_id` instead of deriving geometry from the campaign record
- [ ] `SceneServer` loads geometry from `maps` via `map_id`; switching maps = loading a new map into the same server (campaign_id key unchanged)
- [ ] Data model doc (`docs/architecture/data-model.md`) updated to reflect new schema
- [ ] All existing tests pass; new migration tests cover the FK change
