# #13 · Move overlay occluded by entities in isometric depth order

**Status:** closed
**Opened:** 2026-06-04
**Closed:** 2026-06-07
**Priority:** medium
**Tags:** bug, rendering

The SVG layer stack in `04-dst-aesthetic-sprites.md` places the move overlay (layer 4) uniformly below all entities (layer 5). In isometric projection, entity sprites extend upward from their tile and can visually occlude the diamond move-overlay tiles that painter's algorithm renders before them — specifically, tiles that are in front of an entity in depth order.

A player looking at the board may not see valid-move highlights that are partially hidden behind a taller entity sprite standing behind them in depth order.

Possible fixes:
- Render move overlay polygons interleaved within the depth-sorted entity pass, so each overlay tile is drawn immediately before the entity at the same depth.
- Draw move overlays on top of everything (above layer 5) with a high `fill-opacity` so they remain visible without hiding entities entirely.
- Use SVG `pointer-events` to keep overlays clickable even when visually behind sprites.

**Acceptance criteria**
- [x] All valid-move diamonds are visible regardless of which entities stand nearby
- [x] Click targets on valid-move diamonds remain functional (not occluded by entity `<g>` hit areas)
- [x] No visual regression on the attack/select highlights that already live inside entity `<g>` groups
