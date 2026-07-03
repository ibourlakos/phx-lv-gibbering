# #123 · `Projection` behaviour: define port, implement Isometric + TopDown modules
**Status:** closed
**Opened:** 2026-06-12
**Closed:** 2026-07-03
**Priority:** low
**Tags:** architecture, rendering

> **Closing note (2026-07-03):** the `GibberingEngine.Projection` behaviour and
> `Projection.Isometric` shipped with #169 (WP-S, Phase 2b), which absorbed this
> issue's core scope. `Projection.TopDown` was intentionally not built there — it
> belongs to #124's scope (WP-L), whose sequencing note already says the viewport
> work "switches the scene SVG to use `Projection.TopDown`". Closed to resolve the
> tracker contradiction between this file, the issues index, and WP-S/WP-L notes.

Define a `Projection` behaviour as the render-time interface between world coordinates and screen coordinates, extract the existing isometric math into `Projection.Isometric`, and implement `Projection.TopDown`. Audit current rendering code for any world/screen coordinate mixing and decouple it.

Derived from #101 (DM top-down projection mode discovery). Required before #124 (DM top-down viewport).

## Scope

**Behaviour**

```elixir
defmodule Gibbering.Projection do
  @callback project({x :: integer, y :: integer}, opts :: map) ::
              {screen_x :: number, screen_y :: number}
end
```

`opts` carries tile dimensions and any projection-specific constants (origin offsets for isometric, tile size for top-down).

**`Projection.Isometric`**

Extract the existing isometric projection math (currently inline in the rendering layer) into this module. The formula:

```
sx = (x - y) * tile_w / 2 + origin_x
sy = (x + y) * tile_h / 2 + origin_y
```

**`Projection.TopDown`**

```
sx = x * tile_w
sy = y * tile_h
```

**Rendering pipeline update**

The rendering pipeline (scene SVG generation) must accept a projection module as a parameter rather than hard-coding isometric math. Tiles and entities are projected by calling `projection_module.project({x, y}, opts)`.

**Audit**

Scan the current rendering layer for any locations where isometric screen coordinates are stored in the tile store, entity records, or socket assigns rather than computed at render time. Each instance is either fixed inline or captured as a follow-up issue if the change is non-trivial.

## Notes

- The tile store (`%GridTile{}` records, `grid_data` JSONB) holds world `{x, y}` coordinates only and requires no changes.
- `Projection.TopDown` is intentionally minimal — its main purpose is to prove the abstraction works before #124 builds on it.

**Acceptance criteria**
- [ ] `Gibbering.Projection` behaviour defined with `project/2` callback
- [ ] `Projection.Isometric` implements the behaviour; existing isometric rendering uses it
- [ ] `Projection.TopDown` implements the behaviour
- [ ] Scene SVG rendering pipeline accepts a projection module parameter; no hard-coded isometric math remains in the render path
- [ ] Audit complete: all world/screen mixing either fixed or captured as follow-up issues
- [ ] All existing rendering tests pass unchanged
- [ ] Unit tests for both projection modules covering known coordinate pairs
