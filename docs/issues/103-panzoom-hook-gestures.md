# #103 · PanZoom JS hook: pointer drag, wheel zoom, follow active token

**Status:** closed
**Opened:** 2026-06-07
**Closed:** 2026-06-07
**Priority:** low
**Tags:** rendering, architecture, ui

Implements the zoom and pan mechanics decided in [#81](081-viewport-zoom-pan-architecture.md).
The `PanZoom` hook skeleton is already in `assets/js/app.js` (preserves `this.viewBox`
across LV patches). This issue adds the actual gesture handling.

**Changes required**

1. **Wheel zoom** — on `wheel` event, compute zoom factor `f = 1.1^(-delta/100)`, clamp
   `vbw` to `[svg_w/4, svg_w]`, zoom around cursor SVG position, update `this.viewBox`.
2. **Pointer drag pan** — on `pointerdown`/`pointermove`/`pointerup`, convert screen-pixel
   delta to SVG units, update `this.viewBox`. Clamp x/y to `[-(tile_w/2), svg_w−vbw+tile_w/2]`.
3. **Arrow key pan** — on `keydown`, step by `tile_w/2` SVG units in the pressed direction.
   Only active when focus is on the game board (not an input/select element).
4. **Follow active token** — server renders `data-center-sx` and `data-center-sy` on the
   SVG element (active entity's IsoProjection screen coords). In `updated()`, if these
   changed AND `data-follow="true"`, shift `this.viewBox` to center `(sx, sy)`.
5. **Template** — add `data-center-sx`, `data-center-sy`, and `data-follow="true"` to the
   SVG element in `game_live.html.heex`. Compute sx/sy from the active entity via
   `IsoProjection.to_screen`.
6. **svg_w / svg_h** — the hook needs the raw SVG canvas dimensions (not the viewport
   size) to compute zoom clamps. Read from `data-svg-w` and `data-svg-h` attributes on
   the SVG element.

**Zoom math reference (from #81)**
```
# cursor → SVG coords
cx = x + (px / viewport_w) * vbw
cy = y + (py / viewport_h) * vbh

# new viewBox after zoom by factor f
new_vbw = clamp(vbw / f, svg_w/4, svg_w)
new_vbh = clamp(vbh / f, svg_h/4, svg_h)
new_x   = cx - (cx - x) * (new_vbw / vbw)
new_y   = cy - (cy - y) * (new_vbh / vbh)
```

**Pan clamping**
```
x_min = -(tile_w / 2)
x_max = svg_w - vbw + (tile_w / 2)
y_min = -(tile_h / 2)
y_max = svg_h - vbh + (tile_h / 2)
```

**Acceptance criteria**
- [x] Mouse wheel zooms in/out around the cursor, clamped to [1×, 4×] relative to full SVG
- [x] Pointer drag pans the viewBox; viewBox cannot wander more than one tile outside SVG bounds
- [x] Arrow keys pan by `tile_w/2` SVG units per press when no text input is focused
- [x] When turn changes and `data-follow="true"`, viewBox re-centres on the active entity
- [x] SVG element carries `data-center-sx`, `data-center-sy`, `data-svg-w`, `data-svg-h`, `data-follow`
- [x] Existing `DiceRoll` hook and all phx-click handlers still work after the changes
- [x] `mix precommit` exits 0
