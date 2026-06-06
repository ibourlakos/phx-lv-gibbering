# #98 · DST-inspired art direction — reference tile and entity spec
**Status:** open
**Opened:** 2026-06-06
**Priority:** medium
**Tags:** rendering

Produce a concrete art direction reference before any large content or rendering pass commits to a visual style.

The reference visual style is *Don't Starve Together*: moderately zoomed-out isometric, strong silhouettes, gothic/whimsical tone, muted palette with selective color pops, hand-drawn feel via thick outlines (not clean vector strokes).

Deliverables:
- One reference tile (ground tile) rendered in SVG at the agreed tile size constant — shows base color, subtle texture treatment (SVG filters), grid line style, and elevation shadow
- One reference entity (a human-scale character token) — shows silhouette proportions, outline weight, idle state, HP bar placement, and selection ring treatment
- A small CSS/SVG variable palette definition (background, outline, accent colors for magic/fire/UI)
- A short written spec: what tools/techniques (SVG filters, stroke-width conventions, viewBox per entity) are used and why

This spec gates the multi-style system (#99): you cannot define what a "style" contains until you have a concrete reference instance of one.

**Acceptance criteria**
- [ ] Tile size constant established and documented (e.g., 64 SVG units per tile side)
- [ ] Reference ground tile SVG committed to `priv/static/art-reference/` or equivalent
- [ ] Reference entity SVG committed alongside the tile
- [ ] CSS/SVG variable palette defined (at minimum: bg, outline, terrain-fill, accent-magic, accent-fire)
- [ ] Written spec covers: outline technique, texture pass approach, proportion conventions, filter stack
- [ ] Both reference assets render correctly in Firefox and Chrome without any JS dependency
