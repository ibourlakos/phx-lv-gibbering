# Architecture

> **See also:** [Data Model](data-model.md) — full schema reference for the DB tables, runtime State struct, and static reference data modules.

## Overview

The Gibbering Engine is a deliberate architectural aberration: a 2D tactical game that runs entirely server-side, streaming SVG diffs to the browser over a LiveView WebSocket. No client-side game framework. No manual WebSocket code. The server is the game.

---

## Bounded Context Map

The module structure follows the polytope bounded context decomposition from
[docs/papers/polytope-architecture.md](../papers/polytope-architecture.md). Each bounded
context owns its namespace. No context reaches directly into another's modules — all
cross-context interaction is via the command bus (C) or event bus (E). See #108 for the
EventBus port definition, #109 for the bus classification audit, and #112 for the full
context map document.

### Scene *(Behavioral dimension — core game authority)*

```
Gibbering.Engine.SceneServer  ← single-writer authoritative process (1 GenServer per session)
Gibbering.Engine.State        ← immutable state struct (tiles, entities, selection, turn order)
Gibbering.Engine.Rules        ← pure functions: movement, targeting, combat
Gibbering.Engine.GameSession  ← session supervisor / registry entry
Gibbering.Engine.SpriteCompositor ← sprite composition pipeline
```

Namespace: `Gibbering.Engine.*` (maps to the Scene bounded context in polytope terms;
rename to `Gibbering.Scene.*` is a future refactor tracked separately if desired).

### Rules Engine *(Structural dimension — core domain)*

```
Gibbering.Ruleset                        ← behaviour port: any ruleset must implement this
Gibbering.Rulesets.DnD5e                 ← D&D 5e SRD ruleset (Strategy implementation)
Gibbering.Rulesets.DnD5e.Stats           ← HP, speed, proficiency, stat modifiers
Gibbering.Rulesets.DnD5e.Spell           ← spell resolution, damage, saving throws
Gibbering.Rulesets.DnD5e.RuleModifier    ← modifier struct: source, operation, value
Gibbering.Rulesets.DnD5e.ModifierPipeline ← Chain of Responsibility over modifiers
Gibbering.Rulesets.DnD5e.Predicate       ← composable boolean rule conditions
Gibbering.Rulesets.DnD5e.Condition       ← condition type definitions (Paralyzed, Frightened …)
```

### Content Catalogue *(Structural dimension — core domain)*

```
Gibbering.Catalogue           ← context boundary / public API
Gibbering.Catalogue.Race      ← race definitions with stat bonuses and traits
Gibbering.Catalogue.Class     ← class definitions with features and base stats
Gibbering.Catalogue.Spell     ← spell definitions: damage, range, school
Gibbering.Catalogue.Monster   ← monster stat blocks (SRD-legal subset)
Gibbering.Catalogue.Appearance ← visual metadata for catalogue entries
Gibbering.Catalogue.Style     ← display style declarations
Gibbering.Catalogue.Cache     ← in-process ETS cache over the DB
```

Legacy in-memory reference modules (`Gibbering.Data.Races`, `Gibbering.Data.Classes`,
`Gibbering.Data.Spells`, `Gibbering.Data.Monsters`, `Gibbering.Data.Items`,
`Gibbering.Data.Backgrounds`) are internal helpers within the Content Catalogue context;
they pre-date the DB-backed `Catalogue.*` layer and will be migrated or removed over time.

### Campaign Lifecycle *(Structural dimension — supporting domain)*

```
Gibbering.Campaigns           ← context boundary / public API
Gibbering.Campaign            ← Ecto schema: campaign record
Gibbering.CampaignCharacter   ← Ecto schema: character-in-campaign join
Gibbering.CampaignCharacters  ← context operations over CampaignCharacter
Gibbering.CampaignMember      ← Ecto schema: player membership
Gibbering.CampaignInvitation  ← Ecto schema: invitation record
Gibbering.CampaignInvitations ← context operations over invitations
Gibbering.CampaignInviteLink  ← Ecto schema: shareable invite link
Gibbering.CampaignInviteLinks ← context operations over invite links
Gibbering.Character           ← Ecto schema: character sheet
Gibbering.Characters          ← context operations over characters
```

### Identity and Authorization *(Structural dimension — supporting domain)*

```
Gibbering.Accounts            ← context boundary / public API (users, sessions, auth)
Gibbering.Accounts.User       ← Ecto schema: player account
Gibbering.Admin               ← admin surface of this context (support users, audit)
Gibbering.Admin.SupportUser   ← Ecto schema: admin credential
Gibbering.Admin.AuditLog      ← Ecto schema: admin action log
```

### Observability *(Structural dimension — generic domain)*

```
Gibbering.Monitoring.MetricsStore         ← behaviour port: metric storage backend
Gibbering.Monitoring.Stores.Local         ← ETS-backed adapter (production)
Gibbering.Monitoring.Stores.NoOp          ← no-op adapter (test)
Gibbering.Monitoring.CampaignMetricSnapshot ← snapshot schema
```

### Notification *(Structural dimension — generic domain)*

Namespace: `Gibbering.Notification` (assigned; no module exists yet). Currently
implemented as direct `Phoenix.PubSub` calls scattered across contexts. A thin
wrapper module encapsulating those calls is the planned scope, once the EventBus port
(#108) and bus classification audit (#109) are complete.

### Bus *(Integration dimension — meta-hexagon)*

Namespace: `Gibbering.EventBus` (port/behaviour to be defined by #108). Current
implementation: direct `Phoenix.PubSub` calls at call sites. The EventBus port will
allow swapping to a synchronous in-memory test double or persistent event store without
touching any bounded context.

### Web Adapter *(Presentational dimension)*

```
GibberingWeb.Router             ← /  →  /lobby/:id  →  /game/:id
GibberingWeb.GameLive           ← game board LiveView: event handler + SVG + sprites
GibberingWeb.LobbyLive          ← party setup LiveView
GibberingWeb.CampaignPrepLive   ← DM campaign preparation
GibberingWeb.DashboardLive      ← player dashboard
GibberingWeb.IsoProjection      ← pure functions: grid→screen coordinate math (2:1 dimetric)
GibberingWeb.Components.CharacterSprite ← inline SVG sprite components
```

### Data Pipeline *(Integration dimension — ingestion)*

```
Gibbering.Pipeline.LegalGuard   ← WotC Product Identity filter
```

---

## The Ruleset Behaviour

The engine is ruleset-agnostic. `Gibbering.Ruleset` is a **behaviour** (not a protocol — #14 resolved).
`Engine.State.ruleset` holds the module reference; `Engine.SceneServer` delegates all rule decisions to it.

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
3. They can edit name, race, and class — the lobby recalculates HP, speed, and stat bonuses from `Catalogue.Race` and `Catalogue.Class` (and the legacy `Data.*` in-memory tables for now), then persists to the DB.
4. The DM clicks **Start Game** which navigates to `/game/:id`.

PubSub topic `"lobby:#{campaign_id}"` propagates claim/release events to all connected lobby sessions so multiple browser tabs stay in sync.

> **Known issue (#18):** player identity is tied to the browser session (CSRF token), so two tabs in the same browser share an identity. Proper per-player identity is required before same-browser multi-player works correctly.

> **Known issue (#20):** lobby character edits write to the DB, but a `SceneServer` already running for the same campaign holds a stale in-memory snapshot. The server must be restarted (or the lobby must force a reload) for changes to take effect.

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

**Per-user topics:** Each GameLive socket also subscribes to `"game:#{game_id}:user:#{user_id}"`. The DM can send private whispers (`{:whisper, text}`) to a single player's socket without broadcasting to the main topic. The SceneServer sends the whisper directly via `Phoenix.PubSub.broadcast/3` on that per-user topic without mutating state.

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

## Command Bus (C) vs Event Bus (E) Classification

The polytope compound bus is B = (C, E). Command bus (C): fan-out = 1, addressed, synchronous
(`GenServer.call/cast`). Event bus (E): fan-out ∈ [0, ∞), unaddressed, async (`Phoenix.PubSub`).
The two sets of message types are disjoint — nothing crosses both buses.

**Event bus (E) — PubSub topics and their publishers:**

| Topic | Publisher | Message type | Classification |
|---|---|---|---|
| `"game:#{id}"` | `Engine.SceneServer` | `{:state_updated, state}` | Scene event ✅ |
| `"game:#{id}"` | `Engine.SceneServer` | `:session_ended` | Scene event ✅ |
| `"game:#{id}"` | `Engine.SceneServer` | `{:dm_broadcast, text}` | Notification event ✅ |
| `"game:#{id}:user:#{uid}"` | `Engine.SceneServer` | `{:whisper, text}` | Notification event ✅ |
| `"game:#{id}:user:#{uid}"` | `Gibbering.Admin` | `{:ejected, reason}` | Admin notification ✅ |
| `"system:admin"` | `Monitoring.Stores.Local` | metrics map | Observability event ✅ |
| `"lobby:#{id}"` | `GibberingWeb.LobbyLive` | `:refresh` | UI coordination (intra-web) ✅ |

**Command bus (C) — direct GenServer / function calls between contexts:**

| Caller | Callee | Call type | Classification |
|---|---|---|---|
| Web Adapter (GameLive) | `Engine.SceneServer.*` | `GenServer.call` | Player/DM commands ✅ |
| Web Adapter (LobbyLive) | `Engine.SceneServer.{running?,reload_entities}` | `GenServer.call` | Session lifecycle ✅ |
| Web Adapter | `Campaigns.*` | DB query | Campaign reads ✅ |
| Web Adapter | `Catalogue.*` | ETS/DB query | Reference data reads ✅ |
| Web Adapter | `Accounts.*` | DB query | Identity reads ✅ |
| `CampaignInvitations` | `Campaigns.join_campaign` | function call | Intra-context ✅ |

**Known boundary violations (tracked as issues):**

| Caller | Callee | Issue |
|---|---|---|
| `Monitoring.Stores.Local` | `Engine.SceneServer.get_state` | #114 — Observability queries Scene directly; should subscribe to events |
| `GibberingWeb.Live.Admin.CampaignMonitoringPage` | `Engine.SceneServer.get_state` | #114 — Admin reads Scene directly; same fix |

The violation of `GameLive` calling `Engine.Rules.valid_targets` directly was fixed in #109:
`valid_targets` is now computed inside SceneServer and included in `Engine.State`, so callers
read it from the returned state rather than calling the Rules context directly.

**Enforcement rule:** No bounded context may import or call another context's internal modules.
All cross-context interaction must go through one of:
- **C** — `GenServer.call/cast` on the target context's public API module
- **E** — `Phoenix.PubSub.broadcast/subscribe` on the event bus

A direct module import from one context into another's non-public internals is a boundary
violation. Use the bus classification table above to determine the correct path.

---

## Single-Writer Contract

`Engine.SceneServer` is the **sole emitter** of scene-domain events on its PubSub game
topic. This is the single-writer guarantee that gives total ordering to the scene event
stream:

- SceneServer emits: `{:state_updated, state}`, `:session_ended`, `{:dm_broadcast, text}`,
  `{:whisper, text}` on `SceneServer.topic/1`.
- The Web Adapter (GameLive) **relays** UI-level messages to players but does **not** emit
  domain events on behalf of the Scene context.
- No other bounded context emits events on the scene topic.

The invariant is enforced by convention and verified in `test/engine/scene_server_test.exs`
under the "single-writer contract" describe block. If any process outside SceneServer
broadcasts a scene-domain message on the game topic, total ordering is broken and any future
persistent event log or hash-chained event stream becomes corrupted.

This contract is a prerequisite for the event cascade batch emission pattern (#111) and the
CQRS read model formalization (#113). It also directly constrains the boundary violation
tracked in #114 (Observability and admin querying SceneServer directly).

---

## Open Questions

- ~~Should `Gibbering.Ruleset` be a `behaviour` or a `protocol`?~~ Decided: behaviour (#14 closed)
- Does fog-of-war calculation belong to the engine or the ruleset?
- How does a ruleset declare what UI action buttons to render?
- How should lobby player identity work for same-browser multi-player? (see #18)
- How should lobby edits propagate to a running `SceneServer`? (see #20)