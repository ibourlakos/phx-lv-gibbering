# #9 · `tile_walkable?` crashes on missing tile coordinates

**Status:** open
**Opened:** 2026-06-04
**Priority:** medium
**Tags:** bug

`Map.get(state.grid_tiles, {x, y}).walkable` crashes with a `NilPointerError` (no such function clause) if `{x, y}` is absent from `grid_tiles`. The `within_bounds?` guard in the movement comprehension runs first and prevents the crash in that specific call site, but the guard is not part of `tile_walkable?` itself. Any future caller that skips the bounds check — or any edge case where `grid_tiles` has gaps — will crash silently.

Fix: `tile_walkable?` should pattern-match or use `Map.get/3` with a default and return `false` when the tile is missing.

**Acceptance criteria**
- [ ] `tile_walkable?` returns `false` for any coordinate not present in `grid_tiles`
- [ ] Unit tests cover in-bounds walkable tile, in-bounds wall tile, and missing tile
