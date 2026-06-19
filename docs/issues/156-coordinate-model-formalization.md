# #156 · Coordinate model formalization — game grid, SVG space, surface addresses, edge model
**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** architecture, rendering

Formalize the three-space coordinate model from brainstorm #27. This is a
foundational issue — other spatial systems (traversability, elevation, AoE
targeting) build on top of it.

**Three coordinate spaces:**

1. **Game grid** — `{x, y, elevation}` integers. Canonical address for all game
   logic: entity positions, spell targeting, movement ranges, area of effect.
   `elevation: 0` = ground. Tile = 5 feet.

2. **SVG render space** — `{screen_x, screen_y}` floats derived by `iso_project/4`.
   Used only by the rendering layer; never stored.
   Formula: `screen_x = origin_x + (x - y) * (tile_w / 2)`,
            `screen_y = origin_y + (x + y) * (tile_h / 4) - elevation * (tile_h / 2)`

3. **Surface addresses** — `{object_id, :top}` resolves to `{x, y, elevation + 1}` at
   query time. No separate table; derived from Object records.

**Edge model** (walls and doors):
- Edges addressed as `{tile_coord, direction}` where `direction ∈ {:north, :south, :east, :west}`
- `{x, y, :north}` == `{x, y-1, :south}` — normalise so the lower `{x, y}` is canonical
- Engine state carries an `edges` map: `%{ {x, y, dir} => %{type: :wall | :door, open: bool} }`
- Edges are populated from map seed data; no DB table for v1

**Acceptance criteria**
- [ ] `Gibbering.Engine.Coords` module defines `game_grid/3`, `iso_project/4`, and `edge_key/3` (normalised edge address)
- [ ] `iso_project/4` incorporates elevation with the formula above
- [ ] `Engine.State` gains an `edges` map field (may be empty for existing maps)
- [ ] Seeds updated to populate edges for at least one map with walls/doors
- [ ] All existing coordinate usage in engine and render layers updated to use `Coords` module functions
- [ ] `mix precommit` passes
