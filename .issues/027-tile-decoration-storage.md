# #27 · Tile decoration storage: GridTile field vs decoration entity
**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** discovery, architecture, rendering

Static visual clutter (dead trees, rock clusters, bones, grass tufts) can be stored in two ways:

- **GridTile field** — `decoration: :dead_tree | :rock | nil` on the tile struct. Simple; decoration is non-interactive.
- **Decoration entity** — separate entity type in the entities map, rendered on a decoration layer. More flexible if decorations ever become interactive (e.g. destructible trees).

The brainstorm settled on the tile-field approach for non-interactive clutter, but the decision was not formally locked or implemented.

**Acceptance criteria**
- [ ] Decision written and recorded in architecture docs or this issue
- [ ] `GridTile` (or entity map) updated to reflect the chosen model
- [ ] At least 2–3 decoration types render correctly on the isometric grid (dead tree, rock, bones)
