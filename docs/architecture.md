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
GibberingWeb.GameLive         ← LiveView: event handler + SVG template
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

The `<svg>` element is the entire game viewport. Layers render bottom to top:

| Layer | SVG element | Notes |
|---|---|---|
| Texture defs | `<defs><pattern>` | Loaded once; diffed only on map change |
| Tiles | `<rect fill="url(#texture)">` | Static map geometry |
| Fog of War | `<mask>` | Cuts visibility holes per hero sight radius |
| Move overlay | `<rect phx-click="move_selected">` | Semi-transparent; shown when entity selected |
| Entities | `<g><image><rect>` | Sprite + HP bar; `phx-click="select_entity"` |

Key CSS: `image-rendering: pixelated` on the root `<svg>` for crisp pixel art scaling.

### Why SVG diffs are cheap

When an entity moves, LiveView sends only the changed attributes (`x`, `y` on one `<g>`), not the full map. A 50×50 map move is a few bytes over the wire.

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