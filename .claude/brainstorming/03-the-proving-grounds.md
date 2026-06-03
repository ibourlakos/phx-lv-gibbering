# The Proving Grounds
### Prototype v0 — What We Built and What We Learned

**Date:** 2026-06-04  
**Status:** Working prototype

---

## What It Is

A playable turn-based tactical grid running entirely server-side via Phoenix LiveView + SVG. No JavaScript game framework. No client-side state. The server is the game.

**Try it:** `http://localhost:4000/game/1` (after `docker compose exec app mix run priv/repo/seeds.exs`)

---

## What's in the Prototype

### The Map
10×10 grid. Stone border, grass interior, three interior wall tiles at (4,3), (4,4), (4,6). Rendered as colored SVG `<rect>` elements — no sprites yet, textures are pure color.

### The Entities

| Entity | Type | HP | Speed | Position | Notes |
|---|---|---|---|---|---|
| Warrior | hero | 20 | 30 ft (6 tiles) | (2,5) | Blue square |
| Wizard | hero | 12 | 25 ft (5 tiles) | (2,7) | Purple square |
| The Rock | object | 8 | — | (5,5) | Gray square; destructible |

### The Loop (one turn)

1. Active hero has a yellow dashed border
2. Click the hero → blue move overlay appears (Manhattan distance, speed-based)
3. Click a blue tile → hero moves; if adjacent to a target, red attack highlight appears on that entity
4. Click the red entity → 1d6 damage applied; combat log updates
5. At 0 HP: entity removed, tile flips to `walkable: true` with "rubble" texture
6. Click "End Turn" → next hero becomes active

### Multiplayer
Open two browser tabs to `/game/1`. Any move or attack in one tab reflects instantly in the other via Phoenix PubSub. Zero WebSocket code written by hand.

---

## Architecture Validation

What the prototype confirmed works:

- **LiveView SVG diffs are cheap.** A move is a few bytes — only changed attributes patch through.
- **One GenServer per session** works exactly as expected. State is clean, isolated, and trivially restartable.
- **The Ruleset behaviour abstraction** isn't tested yet (DnD5e is hardcoded), but the GameServer already dispatches through `Rules` as a stateless module — the seam is clean.
- **`stats: map()` on entities** works: Warrior has `%{"speed" => 30, "strength" => 16}`, Wizard has `%{"speed" => 25, "intelligence" => 18}`. Ruleset reads what it needs, ignores the rest.
- **Tags drive behavior**: `"destructible"` on The Rock is the only thing that makes it a valid attack target and causes the tile to flip on death. No type hierarchy needed.

What we hit and fixed:

- **SVG z-order bug**: attack overlay was rendered below the entity sprite layer. Fixed by moving the attack highlight inside the entity `<g>` group and switching `phx-click` conditionally.
- **Docker uid mismatch**: scaffold generated root-owned files. Fixed by pinning the container `app` user to uid 1000.
- **Phoenix 1.8 colocated hooks**: scaffold imports `phoenix-colocated/gibbering` in `app.js`; removed until we have actual hooks to wire up.

---

## What's Missing (Next Steps)

### Immediate gaps
- No sprite art — entities are colored rectangles with a letter initial
- No fog of war — all tiles visible to all players at all times
- Attack has no animation or feedback beyond the log text
- Movement is consumed in full — no partial movement tracking
- No initiative/turn ordering beyond the fixed hero sequence

### Rules gaps
- No attack roll (to-hit) — damage applies unconditionally
- No conditions, modifiers, saving throws
- Wizard has no spells — identical mechanics to Warrior except shorter move range
- The Rock doesn't fight back

### Architecture gaps
- Campaign state is not persisted back to Postgres during a session — a server restart loses all mid-game positions
- No session recovery — if the GameServer crashes, clients get a dead socket
- `Gibbering.Ruleset` behaviour is designed but not implemented — DnD5e logic is directly in `Rules`

---

## Open Questions for Next Brainstorm

- Should Wizard's first unique mechanic be a ranged attack (no movement requirement) or an AOE spell (SVG circle overlay)?
- When do we wire up the first save/load? Before or after the Ruleset behaviour split?
- Fog of war first, or sprites first? (Sprites are more motivating to play with; fog is more architecturally interesting.)
