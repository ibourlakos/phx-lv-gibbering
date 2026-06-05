# #81 · Viewport zoom/pan architecture

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** discovery, rendering, architecture

Design the SVG viewport zoom and pan system for the tactical grid.

At DST-level sprite fidelity a readable sprite needs ~48–64 px wide on screen. A 20×20 map at that scale exceeds a standard browser viewport with no room for UI chrome. Zoom and pan are required.

**Two zoom modes:**
- **Tactical (zoomed in):** full sprite detail, ~10×10 tiles visible; used during active combat
- **Overview (zoomed out):** sprites simplified or silhouetted; full map visible; DM prep or exploration

**SVG approach:** `viewBox` manipulation scales all vector content uniformly with no blurriness. Zoom = shrink/grow the viewBox; pan = offset the viewBox origin.

**Open questions to settle:**
- **Per-player or shared camera?** Per-player `viewBox` in LiveView socket assigns (no broadcast, better UX) vs. shared view driven by the DM / active turn (simpler). Lean: per-player with "follow active token" default.
- **Zoom range:** minimum and maximum viewBox dimensions; how zoom interacts with sprite LOD (see #84).
- **Pan behaviour:** keyboard arrow keys, mouse drag, click on minimap?
- **Minimap:** design for from the start, or bolt on later?
- **`viewBox` state location:** LiveView socket assigns only, or does the server need awareness of client viewports (e.g. for culling sends)?

**Acceptance criteria**
- [ ] All open questions have a documented decision
- [ ] `viewBox` state location and update mechanism are specified
- [ ] Zoom range and pan input model are defined
- [ ] Acceptance criteria for the implementation issue(s) derived from this discovery are written
