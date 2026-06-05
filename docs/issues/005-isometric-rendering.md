# #5 · Isometric rendering overhaul (2:1 dimetric)

**Status:** closed
**Opened:** 2026-06-04
**Closed:** 2026-06-04
**Priority:** high
**Tags:** rendering

Switch the SVG rendering pipeline from top-down square tiles to 2:1 dimetric isometric diamond tiles, matching the Don't Starve Together camera angle. Full spec in `04-dst-aesthetic-sprites.md`.

Covers:
- Replace `<rect>` tile elements with `<polygon>` diamonds using the `(x−y, x+y)` projection
- Add tile decoration layer (dead tree, rock cluster, bones) between tile and entity layers
- Add `decoration` field to `GridTile`
- Depth-sort entity render pass by `y * map_width + x`
- Add shadow `<ellipse>` beneath each entity
- Add `sprite` field to `Entity` struct (atom key; `nil` falls back to colored rect)
- SVG character sprites for Warrior, Wizard, The Rock (inline SVG paths, no raster files)
- Update Proving Grounds seed with decorated tiles

**Acceptance criteria**
- [ ] Tile grid renders as diamonds with correct adjacency and no gaps
- [ ] Entities depth-sort correctly (entities closer to the bottom of screen render on top)
- [ ] All existing click interactions work unchanged (select, move, attack, end turn)
- [ ] Warrior, Wizard, The Rock have distinct SVG sprite shapes (not rectangles)
- [ ] At least 2 decoration types appear on the Proving Grounds map
- [ ] Multiplayer sync still works (two tabs stay in sync)
