# #97 · Full-viewport scene layout model and overlay z-layer system (discovery)
**Status:** closed
**Opened:** 2026-06-06
**Closed:** 2026-06-07
**Priority:** medium
**Tags:** discovery, rendering, architecture, ui

Design and validate the layout model for a full-viewport game canvas where the SVG scene fills 100% of the browser window and all other UI (abilities, HP, turn order, DM controls) floats as overlay layers.

Questions to resolve:
- SVG as document root (`position: fixed`, `100vw × 100vh`) vs. contained in a page layout — confirm this is the right model and there are no LiveView socket / navigation constraints that break it
- Overlay z-layer stack: Scene SVG → scene overlays (rings, ranges) → HUD (HP bars) → action bar → turn order strip → info panel → DM panel → system overlays
- HTML vs. SVG split: what lives inside the SVG (world-anchored elements) and what is positioned HTML (screen-anchored panels)
- Event handling: click/drag on the background vs. on panels — how pointer-events are scoped to avoid conflicts
- Pan/zoom JS hook boundary: what state is purely client-side vs. what the server needs to know
- LiveView navigation: does switching routes tear down the full-viewport layout cleanly?

Output: a layout spec document and a minimal prototype (even a static HTML/SVG file) proving the approach works before any production LiveView refactor.

**Acceptance criteria**
- [x] All open questions above answered with a design decision
- [x] Overlay z-layer stack defined with specific z-index values (or stacking context strategy)
- [x] HTML/SVG split boundary documented
- [x] Pointer-event scoping strategy confirmed
- [x] Minimal static prototype shows the full-viewport layout with placeholder overlay panels
- [x] No LiveView navigation or socket issues identified (or workarounds documented)
- [x] Follow-up implementation issue created if not proceeding directly from this discovery

**Decisions:** see `priv/static/art-reference/README.md` (Full-viewport layout model section).
**Prototype:** `priv/static/art-reference/layout-prototype.html`
**Follow-up:** #102 GameLive full-viewport layout refactor
