# #140 · Invert scroll wheel zoom direction

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-21
**Priority:** low
**Tags:** ui, rendering

Current behaviour: scroll up = zoom out, scroll down = zoom in.
Expected convention: scroll up = zoom in (closer to map), scroll down = zoom out.

Root cause: `Math.pow(1.1, -e.deltaY / 100)` in the PanZoom hook.
Removing the negation (`Math.pow(1.1, e.deltaY / 100)`) flips the direction.

**Acceptance criteria**
- [x] Scrolling up zooms in (smaller viewBox, map appears larger)
- [x] Scrolling down zooms out (larger viewBox, map appears smaller)
- [x] Zoom min/max clamps are unchanged
- [x] `mix precommit` exits 0
