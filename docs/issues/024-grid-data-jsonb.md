# #24 · Consolidate grid_tiles rows into JSONB column

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** architecture, rendering

## Problem

Grid tiles are stored as one DB row per tile (`grid_tiles` table). A 10×10 map = 100 rows; a 30×30 = 900 rows. This creates large join results and makes write amplification worse for map edits.

Brainstorming doc `05-initial-data-entities.md` proposes storing the entire grid in a single `maps.grid_data` JSONB column keyed by `"x,y"` strings, which the engine parses back into `{x, y}` tuples on load.

## Proposed approach

- Migrate `campaigns` to add a `grid_data` JSONB column.
- On load, hydrate `grid_data` into the current `grid_tiles` map shape.
- Drop the `grid_tiles` table once migration is complete.
- Update seeds to insert grid data as JSONB.

## Trade-offs

- Pro: single query to load an entire map; smaller row count; easier partial updates via JSONB operators.
- Con: cannot query individual tiles via SQL without unnesting; all tiles loaded at once (acceptable for tactical maps up to ~50×50).

**Acceptance criteria**
- [ ] `campaigns.grid_data` JSONB column in migration
- [ ] Engine hydrates `grid_data` into `%{{x, y} => %{texture, walkable, decoration}}`
- [ ] `grid_tiles` table dropped after data migration
- [ ] Seeds write grid data as JSONB
- [ ] All existing tests pass
