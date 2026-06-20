# #125 · Tile decoration field and rendering
**Status:** closed
**Opened:** 2026-06-12
**Closed:** 2026-06-20
**Priority:** low
**Tags:** architecture, rendering

Add `decoration` to `%GridTile{}` and render at least three static decoration types on the isometric grid.

Derived from #27 (tile decoration storage discovery — tile-field approach chosen).

## Scope

**Data model**

- Add `decoration: atom | nil` to `%GridTile{}`. Initial valid values: `:dead_tree | :rock | :bones | nil`. Nil means no decoration.
- Update `grid_data` JSONB schema to include the `decoration` key (optional, defaults to `nil` on load)
- Update seeds/fixtures that construct `%GridTile{}` records to include the field

**Rendering**

- In the isometric scene render, for each tile with `decoration != nil`, emit an SVG element on the decoration layer (above ground tiles, below entities)
- Initial art: simple SVG shapes are acceptable — the goal is the rendering pipeline, not pixel-perfect art
  - `:dead_tree` — a thin vertical stroke with a few diagonal branches
  - `:rock` — a small irregular polygon
  - `:bones` — two crossed thin ellipses
- Decoration elements participate in depth sort using the tile's `x + y` key (same as entity depth sort)

**Notes**

- Decorations are purely visual; they have no HP, no interactivity, no entity-map entry
- The decoration layer sits between ground tiles and entities in the SVG layer stack (consistent with the layer order settled in BS-14 / #83)

**Acceptance criteria**
- [x] `%GridTile{}` has a `decoration: atom | nil` field
- [x] `grid_data` JSONB load/save round-trips the `decoration` field correctly
- [x] `:dead_tree`, `:rock`, and `:bones` render visibly on the isometric grid in the correct depth-sort position
- [x] Tiles with `decoration: nil` render unchanged
- [x] Existing rendering tests pass; new snapshot or unit test covers at least one decoration type
