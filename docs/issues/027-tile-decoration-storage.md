# #27 · Tile decoration storage: GridTile field vs decoration entity
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-12
**Priority:** low
**Tags:** discovery, architecture, rendering

## Decision

**Tile-field approach.** Static visual clutter (dead trees, rock clusters, bones, grass tufts) is stored as `decoration: atom | nil` on the `%GridTile{}` struct. Decoration is non-interactive and belongs to the tile, not the entity map.

**Rationale:** Decorations are visual facts about a tile, not actors. Storing them as entities would add entity-map overhead and complicate depth-sort for things that will never move, have HP, or respond to actions. If a decoration ever needs to become interactive (e.g. destructible trees), it graduates to an entity at that point — that is a conscious design choice, not a retrofit.

**If destructible decorations are needed in future:** open a new issue to migrate specific decoration types from the tile field to entity entries. The tile field remains the default for purely visual clutter.

## Implementation

- [#125](125-tile-decoration-field-and-rendering.md) — Add `decoration` field to `%GridTile{}`, update grid data schema, render 2–3 decoration types on the isometric grid

**Acceptance criteria**
- [x] Decision written and recorded
- [ ] Implementation tracked in #125
