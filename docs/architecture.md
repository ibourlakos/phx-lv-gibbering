# Architecture

## Overview

The Gibbering Engine is a deliberate architectural aberration: a 2D tactical game that runs entirely server-side, streaming SVG diffs to the browser over a LiveView WebSocket. No client-side game framework. No manual WebSocket code. The server is the game.

---

## Module Map

```
Gibbering.Engine.GameServer   ← authoritative game state (1 GenServer per session)
Gibbering.Engine.State        ← immutable state struct (tiles, entities, fog, selection)
Gibbering.Engine.Rules        ← pure functions: movement, validation, fog-of-war
Gibbering.Ruleset             ← behaviour (interface) any ruleset must implement
Gibbering.Rulesets.DnD5e      ← D&D 5e SRD ruleset (first implementation)
Gibbering.Pipeline.Parser     ← SRD action string parser (regex → structured maps)
Gibbering.Pipeline.LegalGuard ← WotC Product Identity filter for ingested data
GibberingWeb.IsoProjection    ← pure functions: grid→screen coordinate math (2:1 dimetric)
GibberingWeb.GameLive         ← LiveView: event handler + SVG template + inline sprite components
```

---

## The Ruleset Behaviour

The engine is ruleset-agnostic. Any module implementing `Gibbering.Ruleset` can be dropped into a game session:

```elixir
defmodule Gibbering.Ruleset do
  @callback on_move_requested(state, entity_id, {x, y}) :: {:ok, state} | {:error, reason}
  @callback on_entity_selected(state, entity_id) :: state
  @callback on_combat_action(state, attacker_id, target_id, action) :: state
  @callback valid_moves(state, entity_id) :: [{x, y}]
end
```

`GameServer` holds the ruleset module as plain data and dispatches to it:

```elixir
def start_link(game_id, ruleset \\ Gibbering.Rulesets.DnD5e)
```

Different sessions can run different rulesets simultaneously in the same Phoenix app.

### State must stay generic

Entity stats are `stats: map()`, not typed fields, so any ruleset can store what it needs:

- D&D: `%{strength: 18, dexterity: 14}`
- Cyberpunk: `%{hacking_skill: 7, reflexes: 9}`

---

## SVG Rendering Pipeline

### Projection

The game uses **2:1 dimetric isometric** projection (the same camera angle as Don't Starve Together). All coordinate math lives in `GibberingWeb.IsoProjection` as pure functions.

Grid `(x, y)` → screen `(sx, sy)` with origin offset:
```
sx = (x - y) * (tile_w / 2) + origin_x
sy = (x + y) * (tile_h / 2) + origin_y
```
where `tile_w = 64`, `tile_h = 32`, `origin_x = map_height * 32 + 32`, `origin_y = 64`.

Each tile is a diamond `<polygon>` (4 points: top / right / bottom / left). Entity sprites are upright `<g>` elements that do **not** rotate with the grid — they face the camera, billboard-style.

### Layer stack (bottom to top)

| # | Layer | SVG element | Notes |
|---|---|---|---|
| 1 | Ground tiles | `<polygon>` | Diamond per cell; DST dark palette |
| 2 | Tile decorations | `<g>` (depth-sorted) | Trees, rocks, bones; inline SVG paths |
| 3 | Move overlay | `<polygon phx-click="move">` | Blue diamond; shown when entity selected |
| 4 | Entities | `<g>` (depth-sorted by x+y) | Inline SVG sprite + HP bar |
| 5 | Selection/target highlight | inside entity `<g>` | Diamond ring; always on top of sprite |

**Depth sort:** entities and decorations are sorted ascending by `x + y` before rendering. Lower `x + y` = further from camera = drawn first = appears behind.

### Sprite strategy

Sprites are **inline SVG paths** defined as private function components in `GameLive`, dispatched by `entity.sprite` (string key). No raster files — no asset pipeline, no LFS, no license risk at this stage. The entity's `sprite` field is the hook point for future raster sprites (`<image href="/images/sprites/<key>.png">`).

Key CSS: `image-rendering: pixelated` on the root `<svg>` for crisp scaling when raster sprites arrive.

### Why SVG diffs are cheap

When an entity moves, LiveView sends only the changed attributes (`transform` on one `<g>`), not the full map. A 50×50 map move is a few bytes over the wire.

---

## Multiplayer

No custom WebSocket code. Phoenix PubSub broadcasts `{:state_updated, new_state}` to all LiveViews subscribed to `"game:#{game_id}"`. Each LiveView re-renders only its diff.

---

## Data Pipeline

```
[Open5e JSON / SRD files]
        │
        ▼
LegalGuard.legally_safe?/1     ← drops WotC Product Identity (Beholder, Mind Flayer, etc.)
        │
        ▼
Pipeline.Parser.parse_action_damage/1  ← regex: "Hit: 10 (2d6+3) piercing" → %{dice_count, ...}
        │
        ▼
[PostgreSQL: monsters, spells tables]
```

---

## Open Questions

- Should `Gibbering.Ruleset` be a `behaviour` or a `protocol`? (Behaviour is simpler now; protocol enables structural polymorphism later)
- Does fog-of-war calculation belong to the engine or the ruleset? (Currently engine — but some rulesets may not want it)
- How does a ruleset declare what UI action buttons to render?