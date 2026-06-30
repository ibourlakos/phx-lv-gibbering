# Context Map

> **See also:** [Architecture](../architecture.md) — module listings per context.
> [Bounded Context Graph paper](../papers/bounded-context-graph.md) — integration pattern vocabulary.

This document is the **living context map** for the Gibbering Engine: all bounded contexts, every
inter-context seam, the integration pattern at each seam, and the known violations that need to be
fixed. It is updated whenever a new context is introduced, a seam's pattern changes, or a violation
is resolved.

---

## Context Inventory

| Context | Module namespace | BCG dimension | Owns |
|---|---|---|---|
| Scene | `Gibbering.Engine.*` | Behavioral | Scene state, turn order, entity positions |
| Rules Engine | `Gibbering.Ruleset` (port) + `Gibbering.Rulesets.DnD5e.*` | Structural — core | Rule callbacks, modifier pipelines, conditions |
| Content Catalogue | `Gibbering.Catalogue.*` (+ legacy `Gibbering.Data.*`) | Structural — core | Race, class, spell, monster, appearance reference data |
| Campaign Lifecycle | `Gibbering.Campaigns`, `Gibbering.Campaign`, `Gibbering.Characters.*`, `Gibbering.CampaignCharacter.*`, `Gibbering.CampaignMember`, `Gibbering.CampaignInvitation.*` | Structural — supporting | Campaign records, membership, character templates |
| Identity & Authorization | `Gibbering.Accounts.*`, `Gibbering.Admin.*` | Structural — supporting | User accounts, admin credentials, audit log |
| Observability | `Gibbering.Monitoring.*` | Structural — generic | Metrics snapshots, MetricsStore port, adapters |
| Web Adapter | `GibberingWeb.*` | Presentational | LiveViews, controllers, SVG pipeline, router |
| Data Pipeline | `Gibbering.Pipeline.*` | Integration — ingestion | LegalGuard filter, SRD data parsing |
| Bus | `Gibbering.EventBus.*` | Integration — meta | Event broadcast/subscribe port, adapters |
| Published Language Registry | `Gibbering.Events.*` | Cross-cutting | Shared event struct contracts (owned by no single context) |

**Notification** (`Gibbering.Events.Notification.*`) is a sub-namespace of the Published Language
Registry. A thin `Gibbering.Notification` module (no implementation yet) is planned to encapsulate
direct `Phoenix.PubSub` calls scattered in the scene and web layers.

---

## Seam Table

Every edge in the bounded context graph must have an integration pattern. Pattern vocabulary from
`docs/papers/bounded-context-graph.md` §8:

| From | To | Direction | Pattern | Bus | Notes |
|---|---|---|---|---|---|
| Scene | Bus | emit | Published Language | E | `%EventBatch{}` on `game:#{id}` and per-user topics |
| Web Adapter | Scene | command | Customer-Supplier | C | `GameLive` / `LobbyLive` → `SceneServer` via `GenServer.call` |
| Web Adapter | Bus | subscribe | Published Language | E | `GameLive` projects `%EventBatch{}` scene + notification events |
| Web Adapter | Campaign Lifecycle | query | Customer-Supplier | C | `Campaigns.*`, `Characters.*`, `CampaignInvitations.*` |
| Web Adapter | Identity | query | Conformist | C | `Accounts.*` — web layer accepts identity model as-is |
| Web Adapter | Content Catalogue | query | Customer-Supplier | C | `Catalogue.*` for race/class/spell lookups in lobby |
| Scene | Rules Engine | call | Customer-Supplier | C | `SceneServer` calls `state.ruleset.callback(...)` via `Gibbering.Ruleset` behaviour |
| Campaign Lifecycle | Identity | query | Conformist | C | Campaign membership links `Accounts.User` without translation |
| Observability | Bus | subscribe | Published Language | E | Target: subscribe to scene events for metrics (see violations) |
| Data Pipeline | Content Catalogue | write | Conformist | C | Pipeline writes to Catalogue-owned DB tables; see note below |

**Data Pipeline note:** the pipeline currently writes directly to the DB tables owned by the
Catalogue context. The intended seam is a Catalogue write API (open host service), not direct DB
access. This is a soft violation — acceptable while the ingestion path is internal-only tooling,
but must be formalized before any external data source integration.

**Bus key:**
- **E** — event bus (`Gibbering.EventBus` → `Phoenix.PubSub`); fan-out ≥ 0, asynchronous.
- **C** — command bus (direct `GenServer.call` or synchronous function call); fan-out = 1.

---

## Published Language Seams

All event-typed edges (E) enumerate the exact topics, publishers, and event structs.

### `"game:#{id}"` — Scene domain events

| Publisher | Event type | Struct |
|---|---|---|
| `Engine.SceneServer` | Entity moved | `Gibbering.Events.Engine.EntityMoved` |
| `Engine.SceneServer` | Turn advanced | `Gibbering.Events.Engine.TurnAdvanced` |
| `Engine.SceneServer` | Attack resolved | `Gibbering.Events.DnD5e.AttackResolved` |
| `Engine.SceneServer` | Damage dealt | `Gibbering.Events.DnD5e.DamageDealt` |
| `Engine.SceneServer` | Entity died | `Gibbering.Events.Engine.EntityDied` |
| `Engine.SceneServer` | Condition applied | `Gibbering.Events.DnD5e.ConditionApplied` |
| `Engine.SceneServer` | Condition removed | `Gibbering.Events.DnD5e.ConditionRemoved` |
| `Engine.SceneServer` | Session started | `Gibbering.Events.Engine.SessionStarted` |
| `Engine.SceneServer` | Session ended | `Gibbering.Events.Engine.SessionEnded` |
| `Engine.SceneServer` | DM override applied | `Gibbering.Events.Engine.DmOverrideApplied` |
| `Engine.SceneServer` | Spell cast | `Gibbering.Events.DnD5e.SpellCast` |

All are wrapped in `%Gibbering.Events.EventBatch{}` before broadcast.

**Subscribers on `"game:#{id}"`:**
- `GibberingWeb.GameLive` — projects events into socket assigns for rendering

### `"game:#{id}:user:#{uid}"` — Per-user notifications

| Publisher | Event type | Struct |
|---|---|---|
| `Engine.SceneServer` | DM broadcast to all | `Gibbering.Events.Notification.BroadcastSent` |
| `Engine.SceneServer` | Whisper to one player | `Gibbering.Events.Notification.WhisperDelivered` |

Wrapped in `%EventBatch{}`.

**Subscribers on `"game:#{id}:user:#{uid}"`:**
- `GibberingWeb.GameLive` (each player's socket, per-session)

### `"lobby:#{id}"` — UI coordination (intra-web)

| Publisher | Message | Notes |
|---|---|---|
| `GibberingWeb.LobbyLive` | `:refresh` | Fan-out to all lobby tabs; no typed event struct |

**Subscribers:** other `LobbyLive` sockets for the same campaign.

This is intra-web coordination; it does not cross a bounded context boundary. No Published Language
struct is required as long as the publisher and all subscribers remain inside `GibberingWeb.*`.

### `"system:admin"` — Observability metrics

| Publisher | Message | Notes |
|---|---|---|
| `Monitoring.Stores.Local` | raw metrics map | No typed struct yet — see #68, #69 |

**Subscribers:** `GibberingWeb.Live.Admin.CampaignMonitoringPage`

---

## Anti-Corruption Layer Obligations

An ACL is required whenever a bounded context receives upstream domain events or models and must
insulate its own internal model from upstream vocabulary changes.

| Consumer | Upstream | ACL status | Notes |
|---|---|---|---|
| `GibberingWeb.GameLive` | `Gibbering.Events.Engine.*` | Informal | `handle_info(%EventBatch{events: e}, socket)` projects events into assigns. Not yet a standalone projection module — see #113 |
| `GibberingWeb.Live.Admin.CampaignMonitoringPage` | `"system:admin"` metrics | None | Receives raw maps; no translation layer. Low risk while this is an internal admin page only |

When #113 (CQRS read model formalization) is implemented, each event subscriber should have an
explicit projection module as its ACL boundary. That module owns the translation from Published
Language structs to the consumer context's internal view model.

---

## Known Boundary Violations

| Caller | Callee | Type | Tracking |
|---|---|---|---|
| `Monitoring.Stores.Local` | `Engine.SceneServer.get_state/1` | Command bus — Observability calling Scene directly | #114 |
| `GibberingWeb.Live.Admin.CampaignMonitoringPage` | `Engine.SceneServer.get_state/1` | Command bus — Web Adapter calling Scene directly for read | #114 |

**Enforcement rule:** No bounded context may import or call another context's internal modules.
All cross-context interaction must go through a named seam from the table above (C or E). A
direct module import from one context into another's non-public internals is a boundary violation
visible at code review.

---

## Update Convention

When this document must change:

| Event | Required update |
|---|---|
| New bounded context added | Add row to Context Inventory; add all its seams to the Seam Table |
| New cross-context seam added | Add row to Seam Table; if event-typed, add to the relevant PL Seams section |
| Seam pattern changes (e.g. Conformist → Customer-Supplier after ACL inserted) | Update Seam Table pattern label; add a one-line note explaining when and why |
| New event struct added to `Gibbering.Events.*` | Add row to the relevant PL Seams topic table |
| Known violation fixed | Remove from violations table; update the relevant seam row if the pattern changed |
| New violation introduced | Add to violations table with tracking issue |

Commit message convention for map-only changes: `docs(context-map): <subject>`.
