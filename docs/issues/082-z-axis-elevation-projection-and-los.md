# #82 · Z axis elevation — projection, depth sorting, and LOS

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** discovery, rendering, architecture

Design elevation (Z axis) support in the isometric projection: updated math, depth sorting, tile data model, 3D movement distance, and line-of-sight.

**Projection change:**
Current formula assumes `z = 0`. With elevation:

```
sx = (x - y) * tile_w/2 + origin_x
sy = (x + y) * tile_h/2 - z * tile_h + origin_y
```

Each Z level shifts the entity up by `tile_h` (32 px). A balcony at `z = 1` renders one tile-height above the floor.

**Depth sort:** the current `x + y` key breaks with elevation. A robust key:

```
sort_key = x + y + z * map_size
```

Edge cases exist near stairways where entities at different Z genuinely overlap — needs further design.

**Tile data model:** each `GridTile` gains a `z` integer. Elevated tiles need a visible "wall face" below the surface to show platform height.

**3D movement distance:** D&D 5e's diagonal cost rule (every second diagonal costs 2 squares) must extend to the Z axis. Extends the Chebyshev movement rules from issue #7.

**Line of sight:** does a wall at `z = 1` block a spell cast from `z = 0`? This requires 3D LOS raycasting, not 2D tile adjacency.

**Open questions to settle:**
- Is elevation in scope for the current engine phase, or deferred until zoom/pan (#81) and sprites (#53) ship?
- How do stairways and ramps work on the grid (movement between Z levels)?
- 3D LOS: full raycasting vs. simplified height-band comparison?
- Should `grid_tiles.z` be a DB column or derived from a `decorations` layer?

**Acceptance criteria**
- [ ] All open questions have a documented decision
- [ ] Updated projection formula and depth sort key are documented
- [ ] `grid_tiles` data model change (z field) is specified
- [ ] 3D movement distance and LOS strategy are decided
- [ ] Acceptance criteria for implementation issue(s) are written
