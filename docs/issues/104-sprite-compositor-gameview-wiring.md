# #104 · Wire SpriteCompositor into GameLive entity rendering
**Status:** closed
**Opened:** 2026-06-07
**Closed:** 2026-06-07
**Priority:** medium
**Tags:** rendering, architecture, ui

Implementation follow-up to #100 (SVG fragment store and compositing pipeline — discovery).

`Gibbering.Engine.SpriteCompositor.compose/3` is implemented and unit-tested. This issue wires it into the GameLive template to replace the inline per-entity SVG markup.

Design decisions already settled in #100:
- Compositing is server-side; caller wraps output in `<g transform="translate(sx, sy)">`.
- Layer order: `[:body, :selection_ring, :hp_bar]`.
- Anchor offsets come from `appearances[{"entity", sprite}]["anchor_x/y"]` (default 0).
- No explicit fragment cache yet — rely on LiveView diffing. Add ETS cache only after profiling.
- Named sprite SVGs (warrior, wizard, etc.) retain their hardcoded geometry. The compositor's `:body` layer is the fallback rectangle; named sprites are rendered on top of or alongside it (see note below).

**Note on named sprites:** The current `entity_sprite` component emits hardcoded SVG paths for known sprite keys. The compositor's `:body` layer renders a rectangle. Integration options:
  (a) Compositor calls `entity_sprite` for the body layer (delegating named-sprite geometry).
  (b) Named sprite paths are migrated into compositor-managed `<symbol>` defs in `<defs>`.
  Option (a) is the least-change path; option (b) is the end-state. Start with (a).

**Acceptance criteria**
- [x] GameLive template uses `SpriteCompositor.compose/3` to render entity overlay layers (selection ring, HP bar)
- [x] Named sprite SVG paths continue to render correctly (no regression — 652 tests pass)
- [x] Fallback body rectangle renders for sprites without a named variant (existing behaviour preserved)
- [x] `selected` flag wired: active entity gets selection ring
- [x] HP bar visible for all entities with `max_hp > 0`
- [x] `mix precommit` passes
