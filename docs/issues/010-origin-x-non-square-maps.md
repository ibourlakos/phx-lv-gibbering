# #10 · Isometric `origin_x` formula breaks on non-square maps

**Status:** open
**Opened:** 2026-06-04
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

**Acceptance criteria**
- [ ] `origin_x` is derived from a formula that correctly centers the top tile for any `map_width × map_height` combination
- [ ] SVG `width` attribute is computed as `(map_width + map_height) * tw / 2` to match
- [ ] Verified visually with at least one non-square map (e.g. 16×10) in the Proving Grounds
