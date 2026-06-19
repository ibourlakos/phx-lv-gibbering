# WP-Q · Spatial Model Foundation

**Status:** active
**Source:** brainstorms #27 (coordinate model), #26 (tile occupancy), #25 (elevation)

The foundational spatial layer the rest of the engine builds on: a formal three-space
coordinate model, a rich tile occupancy taxonomy with a computed traversability function,
and the logical elevation axis. These three issues form a strict dependency chain.

---

## Issues

| # | Title | Depends on |
|---|---|---|
| [#156](../issues/156-coordinate-model-formalization.md) | Coordinate model formalization — game grid, SVG space, surface addresses, edge model | — |
| [#157](../issues/157-tile-occupancy-model.md) | Tile occupancy model — 5-category taxonomy, traversability function, entry triggers | #156 |
| [#158](../issues/158-elevation-model.md) | Elevation model — integer Z, render sort, iso_project formula, staircase objects | #156 |

---

## Sequencing

```
#156 (coordinate model + edge model)
  ├─→ #157 (traversability — uses edge keys from #156)
  └─→ #158 (elevation — uses iso_project formula from #156)
```

`#157` and `#158` can run in parallel once `#156` is done.

---

## Active Front

```
#156  ──→  #157
      └──→  #158
```

---

## Out of scope for this WP

- Structure interiors (deferred — depends on structure design and #85 authoring tools)
- Falling mechanics (deferred)
- 3D line of sight (deferred)
- Spatial partitioning / viewport culling (deferred until performance issues arise)
