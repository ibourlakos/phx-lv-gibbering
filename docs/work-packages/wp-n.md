# WP-N · Campaign / Map Restructure Phase 1
**Status:** complete
**Added:** 2026-06-14
**Completed:** 2026-06-17

Derived from Brainstorm #17 settlement. All 3 issues closed. WP completion is a prerequisite for unparking #85 (content creation tools / Phase 2 scene restructure).

## Dependency chain

```
#129 (maps table migration) → #130 (GridTile.movement JSONB) → #131 (entity movement stats + valid_moves)
```

## Issues

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#129](../issues/129-maps-table-phase-1-migration.md) | Phase 1: introduce `maps` table | medium | — |
| [#130](../issues/130-grid-tile-movement-jsonb.md) | `GridTile.movement` JSONB — replace `walkable: boolean` | medium | #129 |
| [#131](../issues/131-entity-movement-stats-and-valid-moves.md) | Entity movement stats + `valid_moves` multi-mode deduction | medium | #130 |

## Notes

Phase 2 (scenes/scene_templates tables) is deferred until #85 brainstorm. This WP being complete is a prerequisite for unparking #85.
