# #140 · Invert scroll wheel zoom direction

**Status:** open
**Opened:** 2026-06-19
**Priority:** low
**Tags:** ui, rendering

Current behaviour: scroll up = zoom out, scroll down = zoom in.
Expected convention: scroll up = zoom in (closer to map), scroll down = zoom out.

Root cause: `Math.pow(1.1, -e.deltaY / 100)` in the PanZoom hook.
Removing the negation (`Math.pow(1.1, e.deltaY / 100)`) flips the direction.

**Acceptance criteria**
- [ ] Scrolling up zooms in (smaller viewBox, map appears larger)
- [ ] Scrolling down zooms out (larger viewBox, map appears smaller)
- [ ] Zoom min/max clamps are unchanged
- [ ] `mix precommit` exits 0
