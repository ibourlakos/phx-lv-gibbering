# #81 · Viewport zoom/pan architecture

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-07
**Priority:** low
**Tags:** discovery, rendering, architecture

Design the SVG viewport zoom and pan system for the tactical grid.

At DST-level sprite fidelity a readable sprite needs ~48–64 px wide on screen. A 20×20 map at that scale exceeds a standard browser viewport with no room for UI chrome. Zoom and pan are required.

**Two zoom modes:**
- **Tactical (zoomed in):** full sprite detail, ~10×10 tiles visible; used during active combat
- **Overview (zoomed out):** sprites simplified or silhouetted; full map visible; DM prep or exploration

**SVG approach:** `viewBox` manipulation scales all vector content uniformly with no blurriness. Zoom = shrink/grow the viewBox; pan = offset the viewBox origin.

---

## Decisions

**Camera ownership: per-player, client-side only**
Each player controls their own camera. `viewBox` state lives exclusively in the
`PanZoom` JS hook (`this.viewBox`). The server never reads or stores client viewBox
values; no camera broadcast. Per-player is better UX and simpler to implement —
there is no shared-camera feature worth the complexity at this stage.

**`viewBox` state location**
The PanZoom hook (already in `app.js`) owns the viewBox string. It is initialised
from the server-rendered `viewBox` attribute on mount, then preserved across every
LV patch in `updated()`. Server sets initial `viewBox="0 0 #{svg_w} #{svg_h}"`.
No socket assigns, no push_event for normal camera movement.

**Zoom range and math**
- Min zoom (zoom out): viewBox = full SVG canvas (see entire map). `vbw = svg_w`, `vbh = svg_h`.
- Max zoom (zoom in): viewBox = SVG canvas / 4. `vbw = svg_w / 4`, `vbh = svg_h / 4` (≈ quarter of map).
- Input: continuous mouse wheel / trackpad. Zoom factor per wheel delta: `1.1^(delta/100)`, clamped.
- Zoom anchors around the cursor position in SVG space:
  - Convert cursor screen pos `(px, py)` → SVG pos: `cx = x + (px/vw) * vbw`, `cy = y + (py/vh) * vbh`
  - `new_vbw = clamp(vbw / f, svg_w/4, svg_w)`, `new_vbh = clamp(vbh / f, svg_h/4, svg_h)`
  - `new_x = cx - (cx - x) * (new_vbw / vbw)`, same for y
- LOD interaction: not part of this issue. #84 can observe viewBox dimensions to trigger sprite simplification.

**Pan input**
- Primary: pointer drag. Screen-pixel delta converted to SVG units:
  `Δsvg_x = -Δpx * (vbw / viewport_w)`, same for y.
- Secondary: arrow keys. Step = `tile_w / 2` SVG units per keypress.
- Minimap: **deferred** to a later issue. No minimap in scope for the implementation.

**Clamping**
Pan is clamped so the viewBox cannot wander more than one tile-width outside the SVG
canvas bounds: `x ∈ [-(tile_w/2), svg_w − vbw + tile_w/2]`, same for y.

**Follow active token**
When the active turn changes, the client should optionally snap the viewBox to center
on the active entity (default: on). Mechanism: the server renders two data attributes
on the SVG element — `data-center-sx={sx}` and `data-center-sy={sy}` — containing the
screen coordinates of the active entity computed via `IsoProjection.to_screen`. In the
hook's `updated()`, if these attributes changed, shift the viewBox to center `(sx, sy)`.
No `push_event` roundtrip needed — LV attribute diffing delivers the update naturally.
A `data-follow="true/false"` attribute (toggled by a player UI control) gates the snap.

---

**Acceptance criteria**
- [x] All open questions have a documented decision
- [x] `viewBox` state location and update mechanism are specified
- [x] Zoom range and pan input model are defined
- [x] Acceptance criteria for the implementation issue(s) derived from this discovery are written

Implementation tracked in [#103](103-panzoom-hook-gestures.md).
