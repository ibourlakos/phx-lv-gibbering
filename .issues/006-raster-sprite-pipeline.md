# #6 · Raster sprite asset pipeline

**Status:** open
**Opened:** 2026-06-04
**Priority:** low
**Tags:** ops, rendering, legal

Design and wire the path for raster sprite files so that when we're ready to add hand-drawn or pixel art sprites we don't have to retrofit the rendering layer. SVG sprites from #5 stay as the v1 implementation; this issue is about the load path only.

Covers:
- Define `priv/static/images/sprites/` as the canonical sprite directory
- Update `GibberingWeb.Endpoint` static config if needed
- Document the legal gate in `docs/legal.md`: every file added to `sprites/` must have its license recorded before the commit
- Evaluate CC0 candidates (Kenney "Tiny Dungeon", LPC) and record findings in `docs/legal.md` — see also #16 for LPC copyleft risk
- Render path: `<image href="/images/sprites/<key>.png">` in the entity SVG group, gated on `entity.sprite != nil` and file existence

**Acceptance criteria**
- [ ] A placeholder sprite PNG loads correctly in the SVG viewport via the static path
- [ ] `docs/legal.md` has a "Sprite assets" section covering evaluation of at least two CC0 candidates
- [ ] At least one raster sprite replaces one SVG-drawn sprite from #5 in the Proving Grounds
