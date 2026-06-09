# Brainstorm #15 — Scene event schema and Published Language

**Status:** settled

## Context

WP-J issues #108 (EventBus behaviour), #111 (event cascade batch emission), and #113 (CQRS read model formalization) all depend on knowing what typed event structs flow across the event bus (E). Currently the system broadcasts bare tuples — `{:state_updated, state}`, `:session_ended`, `{:dm_broadcast, text}` — where `{:state_updated, state}` ships the entire internal `Engine.State` to every subscriber.

This is not a Published Language. The polytope treatise (§8.5) names the intended scene events: `DamageDealt`, `ConditionApplied`, `EntityMoved`, `TurnAdvanced`, `PhaseTransitioned`. Before the EventBus port can be specified and the batch emission pattern designed, the following questions must be settled.

**Cross-references:** #106 (event schema design methodology), #108, #111, #113.

---

## Decisions

### 1. Replace or coexist with `{:state_updated, state}`?

**Decision: Coexist as a transitional strategy; Replace is the long-term goal.**

The `{:state_updated, state}` message ships raw `Engine.State` across a context boundary — a clear Published Language violation. However, LiveView is today's only subscriber and re-renders the entire board from it. Replacing it requires LiveView to maintain a local projection from typed events, which is meaningful scope not yet designed.

The coexist model:
- SceneServer emits a typed `%EventBatch{}` on the bus for all subscribers that care about semantics (Observability, future event log, spectator feed, animation sequencer).
- SceneServer also continues to emit `{:state_updated, state}` **exclusively for the Web Adapter**, explicitly labelled as a convenience projection pending LiveView migration.
- The two messages share the same PubSub game topic (subscribers filter by pattern).
- A dedicated follow-up issue tracks removing `{:state_updated, state}` once LiveView projects from events.

This is intentional and time-bounded — not "both forever."

---

### 2. Canonical set of scene event types

**Decision: 11 events for the initial set (10 from the proposed table + `HPAdjusted`).**

| Event | Triggered by | Key payload fields |
|---|---|---|
| `EntityMoved` | `move_entity` | `entity_id`, `from`, `to`, `cost_ft` |
| `AttackResolved` | `attack_entity` | `attacker_id`, `target_id`, `roll`, `hit?` |
| `DamageDealt` | attack or spell that hits | `target_id`, `amount`, `damage_type`, `new_hp` |
| `ConditionApplied` | attack effect, DM apply | `entity_id`, `condition_id`, `source_id`, `duration` |
| `ConditionRemoved` | end of duration, save, DM | `entity_id`, `condition_id`, `reason` |
| `TurnAdvanced` | `end_turn`, `force_end_turn` | `from_entity_id`, `to_entity_id`, `round_number` |
| `PhaseTransitioned` | `transition_phase` | `from_phase`, `to_phase` |
| `SpellCast` | `cast_spell` | `caster_id`, `spell_key`, `target_id`, `outcome` |
| `ResourceConsumed` | spell slot use, rage | `entity_id`, `resource_key`, `amount_used`, `remaining` |
| `SessionEnded` | `end_session` | `campaign_id` |
| `HPAdjusted` | DM override | `entity_id`, `old_hp`, `new_hp`, `reason` |

**`AttackResolved` and `DamageDealt` are separate events.** A miss produces `AttackResolved(hit?: false)` with no `DamageDealt`. This mirrors real 5e mechanics: the attack resolution and the damage resolution are distinct steps. Subscribers (combat log, animation) need to distinguish them.

**`HPAdjusted` is added** as a DM intervention event. DMs can set HP directly (outside normal combat flow, see #32). Without it, HP deltas caused by DM override are invisible to Observability and the event log.

**`VisibilityToggled` is deferred** — requires fog-of-war infrastructure not yet designed.

---

### 3. Event envelope and per-event fields

**Decision: IDs only; include `new_hp`; include `causation_id`, `correlation_id`, and `sequence_number`.**

**Denormalized names vs IDs only:** IDs only. Entity names are derivable from the Content catalog. Including `attacker_name: "Aldric"` creates an update anomaly — a rename would require schema migration. Names belong in each subscriber's ACL/projection, not in the Published Language.

**`new_hp` in `DamageDealt`:** Include it. Post-damage HP is a fact about the event outcome that Observability (health tracking) and the Web Adapter (HP bar rendering) both need immediately. Omitting it forces every subscriber to track cumulative state themselves, which is a worse coupling. The binding concern — "it requires SceneServer to include current state" — is acceptable because SceneServer is the Single Writer and already holds this state authoritatively at emit time.

**`causation_id` and `correlation_id`:** Include on every event per #106 and #111:
- `correlation_id` — the user action (command) that initiated the cascade. All events in a batch share it.
- `causation_id` — the direct cause of this specific event within the cascade (the preceding event's `event_id`, or the command id for the first event).

**`sequence_number`:** Include as a per-batch integer, not global. Orders events within a single `%EventBatch{}`. Subscribers can reconstruct causal order from the `causation_id` chain; `sequence_number` is a convenience for ordered iteration.

**Canonical event envelope** (applied to every scene event struct):
```
event_id          :: UUID
event_type        :: atom  (module name alias, e.g. :entity_moved)
schema_version    :: integer
occurred_at       :: DateTime
correlation_id    :: UUID
causation_id      :: UUID
sequence_number   :: non_neg_integer
payload           :: map   (event-specific fields)
```

---

### 4. Cascade batch structure

**Decision: `%Gibbering.Events.EventBatch{}` typed struct.**

```elixir
%Gibbering.Events.EventBatch{
  batch_id:       UUID,
  command:        atom,
  correlation_id: UUID,
  occurred_at:    DateTime,
  events:         [%Gibbering.Events.Scene.*{...}]
}
```

**Rejected: `{:events, [...]}`** — a bare tuple is marginally better than `{:state_updated, state}` but still untyped and unpattern-matchable by struct guards. Inconsistent with the Published Language goal.

**Rejected: per-event `batch_id`** — requires every subscriber that cares about causal order to reassemble from raw events. Adds complexity to every subscriber and makes atomic receipt of a causal chain impossible.

**Chosen: `%EventBatch{}`** — first-class typed concept. Subscribers pattern-match `%EventBatch{}` cleanly. The Web Adapter gets the full ordered `events` list for animation sequencing. The event log stores it atomically. Observability iterates events for metric counters. `EventBus` exposes a `broadcast_batch/2` call.

The `correlation_id` on the batch matches the `correlation_id` on each contained event (the batch is the causal envelope; events point back to it).

---

### 5. Fate of `{:dm_broadcast, text}` and `{:whisper, text}`

**Decision: Move to a dedicated notification topic + typed structs under `Gibbering.Events.Notification.*`.**

These are not scene-domain events — they are notifications from the DM to players. The polytope treatise (§8.5) explicitly separates Notification events (`BroadcastSent`, `WhisperDelivered`) from scene events. Keeping them on the game topic mixes concerns and forces scene subscribers to pattern-match them away.

Typed structs:
- `{:dm_broadcast, text}` → `%Gibbering.Events.Notification.BroadcastSent{campaign_id, text, sent_at}`
- `{:whisper, text}` → `%Gibbering.Events.Notification.WhisperDelivered{campaign_id, target_player_id, text, sent_at}`

PubSub topic: `"notifications:#{campaign_id}"` — separate from `"game:#{campaign_id}"`.

LiveView (and any future player client) subscribes to both topics. Scene analytics subscribers need only the game topic.

---

### 6. Module location for event struct definitions

**Decision: `Gibbering.Events.*` — top-level, owned by no single bounded context.**

Per treatise §3.2: "the Published Language is the polytope's shared artifact. No single context should own the event schema definition for events that cross its boundary."

- `Gibbering.Engine.Events.*` — wrong: owned by the Engine context.
- Inline in `Gibbering.EventBus` — wrong: co-located with transport infrastructure.
- **`Gibbering.Events.*`** — correct: top-level shared namespace, no single bounded context owns it.

Sub-namespace layout:
```
Gibbering.Events
├── EventBatch          ← the batch envelope (not scene-specific)
├── Scene
│   ├── EntityMoved
│   ├── AttackResolved
│   ├── DamageDealt
│   ├── ConditionApplied
│   ├── ConditionRemoved
│   ├── TurnAdvanced
│   ├── PhaseTransitioned
│   ├── SpellCast
│   ├── ResourceConsumed
│   ├── SessionEnded
│   └── HPAdjusted
├── Notification
│   ├── BroadcastSent
│   └── WhisperDelivered
└── Campaign            ← future: PlayerJoined, SessionStarted, etc.
```

`docs/architecture.md` will reference `Gibbering.Events` as the Published Language registry.

---

## Issues to open after settling

- **Scene event struct definitions** — define `%EventBatch{}` and all `Gibbering.Events.Scene.*` structs with typed fields; follow the envelope spec from #106. This directly unblocks #108.
- **Notification event structs + topic migration** — define `Gibbering.Events.Notification.*` structs; update SceneServer to broadcast on `"notifications:#{campaign_id}"`; update LiveView subscription.
- **SceneServer: coexist broadcast pattern** — update SceneServer to emit `%EventBatch{}` per command alongside the existing `{:state_updated, state}` (which remains for Web Adapter until LiveView projection is ready). Track removal of `{:state_updated, state}` as a follow-up.
- **#108 (EventBus behaviour)** — now unblocked: namespace is `Gibbering.EventBus`, event types are `Gibbering.Events.*`, `broadcast_batch/2` is a required callback.
- **Architecture doc update** — document `Gibbering.Events.*` as the Published Language registry in `docs/architecture.md`; note the coexist transition status of `{:state_updated, state}`.
