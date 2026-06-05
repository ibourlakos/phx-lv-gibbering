# Architecture

> **See also:** [Data Model](data-model.md) — full schema reference for the DB tables, runtime State struct, and static reference data modules.

## Overview

The Gibbering Engine is a deliberate architectural aberration: a 2D tactical game that runs entirely server-side, streaming SVG diffs to the browser over a LiveView WebSocket. No client-side game framework. No manual WebSocket code. The server is the game.

---

## Module Map

### Engine (server-side game authority)

```
Gibbering.Engine.GameServer   ← authoritative game state (1 GenServer per session)
Gibbering.Engine.State        ← immutable state struct (tiles, entities, selection, turn order)
Gibbering.Engine.Rules        ← pure functions: movement, targeting, combat
```

### D&D 5e Data Layer

```
Gibbering.Data.Races          ← race definitions: Human, Elf, Gnome (stat bonuses, traits, speed)
Gibbering.Data.Classes        ← class definitions: Fighter, Wizard, Rogue (features, spells, base stats)
Gibbering.Data.Spells         ← spell definitions: cantrips + level-1 spells (damage, range, school)
```

These are pure in-memory data modules (no DB). The `Entity` schema stores the result
(`race`, `class`, `stats` map) after the lobby applies them at character setup time.

### Web Layer

```
GibberingWeb.Router           ← /  →  /lobby/:id  →  /game/:id
GibberingWeb.PageController   ← home page: queries campaigns from DB
GibberingWeb.LobbyLive        ← party setup LiveView (claim slots, pick race/class, edit name)
GibberingWeb.GameLive         ← game board LiveView: event handler + SVG template + sprite components
GibberingWeb.IsoProjection    ← pure functions: grid→screen coordinate math (2:1 dimetric)
```

### Planned (not yet implemented)

```
Gibbering.Ruleset             ← behaviour any ruleset must implement (see #14)
Gibbering.Rulesets.DnD5e      ← D&D 5e SRD ruleset (see #14)
Gibbering.Pipeline.Parser     ← SRD action string parser (see #8)
Gibbering.Pipeline.LegalGuard ← WotC Product Identity filter (see docs/legal.md)
```

---

## The Ruleset Behaviour

The engine is ruleset-agnostic. `Gibbering.Ruleset` is a **behaviour** (not a protocol — #14 resolved).
`Engine.State.ruleset` holds the module reference; `SceneServer` delegates all rule decisions to it.

```elixir
defmodule Gibbering.Ruleset do
  @callback collect_modifiers(entity, action, state) :: [RuleModifier.t()]
  @callback initial_resources(entity) :: map()
  @callback initial_action_economy(entity) :: map()
  @callback advance_turn(entity) :: entity
end
```

`Engine.State` holds the ruleset module as a plain field (default `Gibbering.Rulesets.DnD5e`).
All `DnD5e.*` subsystems live under `Gibbering.Rulesets.DnD5e.*` (Stats, Spell, RuleModifier, Condition).

### State must stay generic

Entity stats are `stats: map()`, not typed fields, so any ruleset can store what it needs:

- D&D 5e: `%{"strength" => 16, "dexterity" => 14, "spells" => ["fire_bolt", "magic_missile"]}`
- Cyberpunk (hypothetical): `%{"hacking_skill" => 7, "reflexes" => 9}`

The `Gibbering.Data.{Races,Classes,Spells}` modules provide static lookup tables that inform stat calculation at character creation time (in the lobby). They are not invoked at runtime by the engine.

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

Sprites are **inline SVG paths** defined as public function components in `GibberingWeb.GameLive`, dispatched by `entity.sprite` (string key). Being public allows the lobby card preview to reuse them. Current sprite keys follow the `"{race}_{class}"` convention for player characters (e.g. `"elf_wizard"`, `"gnome_rogue"`); NPCs and objects use freeform keys (`"rock"`).

No raster files — no asset pipeline, no LFS, no license risk at this stage. The entity's `sprite` field is the hook point for future raster sprites (`<image href="/images/sprites/<key>.png">`).

> **TODO (see #19):** sprite components should be extracted to a dedicated `GibberingWeb.Components.EntitySprites` module rather than living in a LiveView.

Key CSS: `image-rendering: pixelated` on the root `<svg>` for crisp scaling when raster sprites arrive.

### Why SVG diffs are cheap

When an entity moves, LiveView sends only the changed attributes (`transform` on one `<g>`), not the full map. A 50×50 map move is a few bytes over the wire.

---

## Party Setup Flow

```
/ (home)  →  /lobby/:id  →  /game/:id
```

The lobby (`GibberingWeb.LobbyLive`) is a LiveView where players claim character slots before the game starts:

1. Each browser session gets a player identity (currently derived from the session CSRF token — see #18 for the known limitation).
2. A player clicks **Play as [name]** to claim a hero entity slot.
3. They can edit name, race, and class — the lobby recalculates HP, speed, and stat bonuses from `Data.Races` and `Data.Classes`, then persists to the DB.
4. The DM clicks **Start Game** which navigates to `/game/:id`.

PubSub topic `"lobby:#{campaign_id}"` propagates claim/release events to all connected lobby sessions so multiple browser tabs stay in sync.

> **Known issue (#18):** player identity is tied to the browser session (CSRF token), so two tabs in the same browser share an identity. Proper per-player identity is required before same-browser multi-player works correctly.

> **Known issue (#20):** lobby character edits write to the DB, but a `GameServer` already running for the same campaign holds a stale in-memory snapshot. The server must be restarted (or the lobby must force a reload) for changes to take effect.

---

## Client-Side: JS Hooks

LiveView hooks are registered in `assets/js/app.js`:

| Hook | Element | Purpose |
|---|---|---|
| `DiceRoll` | `#game-board` | Listens for `roll_dice` push events; animates a tumbling SVG d6 across the viewport |

The `roll_dice` event carries `%{result: 1..6, label: string}`. The die enters from a random screen edge, lands at centre with a bounce, displays the result pip face and label, then slides off.

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

- ~~Should `Gibbering.Ruleset` be a `behaviour` or a `protocol`?~~ Decided: behaviour (#14 closed)
- Does fog-of-war calculation belong to the engine or the ruleset?
- How does a ruleset declare what UI action buttons to render?
- How should lobby player identity work for same-browser multi-player? (see #18)
- How should lobby edits propagate to a running `GameServer`? (see #20)