# CQRS Read Model

## Boundary statement

`%Engine.State{}` is an internal implementation detail of the Scene bounded context.
Nothing outside Scene should depend on its shape or obtain a copy of it directly. The
boundary rule:

> **SceneServer does not push its internal state struct to subscribers. Adapters subscribe
> to events and maintain their own projections.**

`SceneServer.get_state/1` is permitted at mount time as a one-shot snapshot seed (see
[state_snapshot and late-join](event-cascade.md#state_snapshot-and-late-join)). Once the
projection layer is complete, even mount-time state can be rebuilt from the event
history, making `get_state/1` a performance optimisation rather than a necessity.

Two modules currently violate this boundary by calling `get_state/1` outside of mount
(tracked by #114):

- `GibberingTalesWeb.Monitoring.Stores.Local` — polls scene state for metrics snapshots
- `GibberingTalesAdmin.Admin.CampaignMonitoringPage` — reads scene state for the admin view

## Projections

A **projection** is a struct maintained by an adapter that contains only the fields that
adapter needs, in the shape it needs them. Each projection is updated by consuming events
from the bus; the adapter never reads `%Engine.State{}` directly.

Three projections are defined at minimum. A fourth is sketched for the Observability
context (fixes #114).

### Player projection

Used by the player-role LiveView (currently `GameLive` handles all roles; a dedicated
`PlayerLive` is a future split). Contains only information a player is permitted to see.

| Field | Source event(s) |
|---|---|
| `entities` (visible only) | `%EntityMoved{}`, `%HPAdjusted{}`, `%ConditionApplied{}`, `%ConditionRemoved{}` |
| `turn_order` | `%TurnAdvanced{}` |
| `active_entity_id` | `%TurnAdvanced{}` |
| `phase` | `%PhaseTransitioned{}` |
| `round_number` | `%TurnAdvanced{}` |
| `available_actions` | `%TurnAdvanced{}` (recomputed from ruleset after advance) |
| `session_log` (public messages) | `%BroadcastSent{}` |

Hidden entities are excluded. The `fog_of_war` mask (#26) gates which entity positions
are visible.

### DM projection

A superset of the player projection. The DM sees everything, including hidden entities
and the full session log.

| Additional field | Source event(s) |
|---|---|
| `hidden_entities` | `%EntityMoved{}`, DM toggle events |
| All entity HP (including hidden) | `%HPAdjusted{}`, `%DamageDealt{}` |
| Full `session_log` | `%BroadcastSent{}`, `%WhisperDelivered{}` |
| DM-only conditions / resource state | `%ConditionApplied{}`, `%ResourceConsumed{}` |

### Spectator projection (future — required by #92)

Read-only. Same visibility rules as the player projection: fog-of-war applies, hidden
entities are masked. Updated from the event bus (or from a recorded event history for
replay). No socket-level write access.

### Observability projection (fixes #114)

Maintained by `Monitoring.Stores.Local`. Subscribes to `"game:#{campaign_id}"` and
updates a local snapshot on each `%EventBatch{}` rather than calling `get_state/1`.

| Field | Source |
|---|---|
| `entity_count` | `%EventBatch{}` arrival (recount from projection) |
| `active_phase` | `%PhaseTransitioned{}` |
| `hp_stats` (min/max/mean across entities) | `%HPAdjusted{}`, `%DamageDealt{}` |
| `last_updated_at` | wall clock on each batch |

`Admin.CampaignMonitoringPage` then reads from the Observability projection (or its
own subscription to the same events) rather than calling `SceneServer.get_state/1`.

## Migration path

The current model is **snapshot-based**: every command broadcasts the full
`%Engine.State{}` in `batch.state_snapshot` and LiveView replaces `socket.assigns.game_state`
wholesale. The migration is incremental — both models coexist during transition.

**Phase 1 — define projection structs** (no runtime change)

Create `GibberingTalesWeb.Projections.PlayerView`, `GibberingTalesWeb.Projections.DmView`, and
`GibberingTales.Monitoring.Projection` structs. Each has a `apply(projection, event)` function
that returns the updated projection given a single typed event. Test these as pure
functions — no LiveView, no PubSub required.

**Phase 2 — wire projections into LiveViews** (parallel with snapshot)

On mount: seed from `SceneServer.get_state/1` snapshot → convert to projection struct.
On `%EventBatch{}`: fold `batch.events` through the projection's `apply/2`, then assign
the updated projection to socket. The snapshot in the batch becomes a fallback for any
event type not yet covered by a projection function.

**Phase 3 — remove snapshot dependency**

Once every command's event cascade has a corresponding `apply/2` clause, the
`state_snapshot` field in `%EventBatch{}` is no longer needed for LiveView rendering.
It can be kept as a debug aid or stripped from the broadcast to reduce payload size.

**Phase 4 — remove `get_state/1` from non-mount callers** (closes #114)

`Monitoring.Stores.Local` and `Admin.CampaignMonitoringPage` subscribe to events and
maintain their own projections. `SceneServer.get_state/1` remains for mount-time seeding
and debugging but is no longer called from outside Scene in the steady state.

## Snapshot / Memento strategy

Replaying the full event history to rebuild a projection is expensive for long sessions.
The snapshot at mount time (`SceneServer.get_state/1`) is the pragmatic Memento: it
represents the materialized state at that instant, and the projection function only needs
to process events that arrive *after* mount.

When a persistent event log is introduced (#111), the pattern extends naturally:

1. Persist a snapshot of each projection at regular intervals (e.g. every N events or
   at session end).
2. On cold reconnect, load the most recent snapshot and replay only the delta.
3. `SceneServer.get_state/1` at mount remains the in-process equivalent of step 1+2 for
   in-memory sessions.
