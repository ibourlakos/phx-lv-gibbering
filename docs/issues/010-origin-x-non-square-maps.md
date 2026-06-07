# #10 · Isometric `origin_x` formula breaks on non-square maps

**Status:** closed
**Opened:** 2026-06-04
**Closed:** 2026-06-07
**Priority:** low
**Tags:** bug, rendering

The isometric projection formula in `04-dst-aesthetic-sprites.md` computes:

```
origin_x = map_height * (tw / 2)
```

This correctly centers the top tile of the grid only when `map_width == map_height`. For rectangular maps, the top tile drifts off-center because the horizontal span of the grid depends on both dimensions: `(map_width + map_height) * tw / 2`. The centered formula should be:

```
origin_x = map_height * (tw / 2)   # anchors left edge — correct
# For true center-top alignment:
# svg_width  = (map_width + map_height) * tw / 2
# origin_x   = map_height * (tw / 2)   ← top tile lands at svg_width / 2 only when map_width == map_height
```

The v0 prototype uses a fixed 10×10 grid so the bug is invisible today. It will surface if map dimensions ever change.

**Resolution:** The brainstorming formula (`map_h * tw/2`) was wrong — zero margins. The code already had
the correct formula (`map_h * tw/2 + tw/2`), which gives equal half-tile margins on both sides for any
map shape. "Centering the top tile at svg_width/2" is only coincidentally true for square maps; enforcing
it for wide maps clips the rightmost tiles outside the canvas. The fix was to:
- Expand `to_screen/3` → `to_screen/4` and `origin_x/1` → `origin_x/2` to accept `map_w` explicitly
  (forwards-compatible, even though the formula currently only needs `map_h`)
- Add property-based tests covering both square and non-square maps (16×10 bounds check)
- Document the equal-margin invariant in code and tests

**Acceptance criteria**
- [x] `origin_x` is derived from a formula that correctly produces equal half-tile margins for any `map_width × map_height` combination
- [x] All tiles (including edge tiles) land within SVG bounds for non-square maps — verified by 16×10 test
- [x] `to_screen` and `origin_x` accept `map_w` explicitly in their signatures
