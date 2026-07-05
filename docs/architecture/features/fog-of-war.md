# Fog of War

Fog of war is a **split ownership** problem: the geometry of line-of-sight is engine data; the
rules of vision (range, type, special senses) are ruleset data. Neither can own the whole
calculation without breaking the bounded context boundary — the ruleset must not import tile
geometry, and the engine must not hardcode D&D vision rules.

## Ownership split

**Engine owns:**
- `Engine.Rules.line_of_sight?(from_tile, to_tile, tiles) :: boolean` — pure geometric LOS,
  reads `tile.blocks_sight`. No ruleset dependency.
- `Engine.Rules.visible_tiles(entity, state) :: MapSet.t(tile_coord)` — combines LOS geometry
  with the ruleset's vision callbacks to produce the final visible tile set for an entity.
- `Engine.State.visible_tiles` — per-entity visible tile map, computed after each command and
  stored in state so `state_snapshot` carries it to LiveView without recomputation.
- The SVG fog mask layer — a `<rect>` overlay with a `<clipPath>` per tile, applied during
  rendering based on `socket.assigns.game_state.visible_tiles[current_player_entity_id]`.

**Ruleset owns:**
- `c:vision_range(entity) :: non_neg_integer() | :unlimited` — how many tiles (`:unlimited`
  for Truesight / Blindsight with no stated range).
- `c:vision_type(entity) :: :normal | :darkvision | :blindsight | :truesight | :tremorsense`
  — determines whether darkness, magical darkness, or concealment applies. The engine passes
  this type to the LOS calculation to decide whether blocked-by-darkness tiles count.

See [ruleset-behaviour.md](../ruleset-behaviour.md) for the full `GibberingEngine.Ruleset` callback list.

## Why not ruleset-owned `visible_tiles/2`?

A `visible_tiles(entity, state)` callback on the ruleset would require the ruleset to traverse
tile geometry — importing `Engine.State` internals. That is a bounded context violation: the
Rules Engine context must not reach into the Scene context's data model.

## First implementation notes

When fog of war is first implemented, follow this model:
1. Add `blocks_sight: boolean` to the tile struct (engine data, no ruleset involvement)
2. Implement `Engine.Rules.line_of_sight?/3` as a geometric ray-cast
3. Add `vision_range/1` and `vision_type/1` to `GibberingEngine.Ruleset` with D&D 5e defaults
4. Compute `visible_tiles` inside `SceneServer` after each command; store in `Engine.State`
5. `GameLive` reads `state_snapshot.visible_tiles` and applies the SVG mask — no extra
   subscriptions, no separate calculation in the web layer
