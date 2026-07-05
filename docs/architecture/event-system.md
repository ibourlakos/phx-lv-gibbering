# Event System

## Command Bus (C) vs Event Bus (E)

The polytope compound bus is B = (C, E). Command bus (C): fan-out = 1, addressed, synchronous
(`GenServer.call/cast`). Event bus (E): fan-out ∈ [0, ∞), unaddressed, async (`Phoenix.PubSub`).
The two sets of message types are disjoint — nothing crosses both buses.

**Event bus (E) — PubSub topics and their publishers:**

| Topic | Publisher | Message type | Classification |
|---|---|---|---|
| `"game:#{id}"` | `Engine.SceneServer` | `%EventBatch{}` | Scene event cascade ✅ |
| `"notifications:#{id}"` | `Engine.SceneServer` | `%BroadcastSent{}` | DM narrative broadcast ✅ |
| `"notifications:#{id}"` | `Engine.SceneServer` | `%WhisperDelivered{}` | DM private whisper ✅ |
| `"game:#{id}:user:#{uid}"` | `GibberingTalesAdmin.Admin` | `{:ejected, reason}` | Admin notification ✅ |
| `"system:admin"` | `Monitoring.Stores.Local` | metrics map | Observability event ✅ |
| `"lobby:#{id}"` | `GibberingTalesWeb.LobbyLive` | `:refresh` | UI coordination (intra-web) ✅ |

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
| `GibberingTalesAdmin.Admin.CampaignMonitoringPage` | `Engine.SceneServer.get_state` | #114 — Admin reads Scene directly; same fix |

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

`Engine.SceneServer` is the **sole emitter** on its two PubSub topics. This single-writer
guarantee gives total ordering to the scene event stream:

- `SceneServer.topic/1` (`"game:#{id}"`) — exclusively emits `%EventBatch{}` after every
  command that mutates scene state. No bare tuples; no other process broadcasts here.
- `SceneServer.notifications_topic/1` (`"notifications:#{id}"`) — exclusively emits
  `%BroadcastSent{}` and `%WhisperDelivered{}`. Also exclusively owned by SceneServer.
- The Web Adapter (GameLive) **relays** UI-level messages to players but does **not** emit
  domain events on behalf of the Scene context.
- No other bounded context emits events on these topics.

The invariant is enforced by convention and verified in `test/engine/scene_server_test.exs`
under the "single-writer contract" describe block. If any process outside SceneServer
broadcasts a scene-domain message on either topic, total ordering is broken and any future
persistent event log or hash-chained event stream becomes corrupted.

This contract is realised by the [event cascade batch emission pattern](event-cascade.md) (#111) and the
[CQRS read model formalization](cqrs-read-model.md) (#113). It also directly constrains the boundary violation
tracked in #114 (Observability and admin querying SceneServer directly).
