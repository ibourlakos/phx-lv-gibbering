# Brainstorm #15 — Scene event schema and Published Language

**Status:** settled

## Context

WP-J issues #108 (EventBus behaviour), #111 (event cascade batch emission), and #113 (CQRS read model formalization) all depend on knowing what typed event structs flow across the event bus (E). Currently the system broadcasts bare tuples — `{:state_updated, state}`, `:session_ended`, `{:dm_broadcast, text}` — where `{:state_updated, state}` ships the entire internal `Engine.State` to every subscriber.

This is not a Published Language. The polytope treatise (§8.5) names the intended scene events: `DamageDealt`, `ConditionApplied`, `EntityMoved`, `TurnAdvanced`, `PhaseTransitioned`. Before the EventBus port can be specified and the batch emission pattern designed, the following questions must be settled.

**Cross-references:** #106 (event schema design methodology), #108, #111, #113.

---

## Decisions

### 1. Replace `{:state_updated, state}` with typed events

**Decision: Replace entirely. No coexistence.**

`{:state_updated, state}` ships raw `Engine.State` across a context boundary — a direct Published Language violation. Since there are no current subscribers beyond LiveView, this is the right moment to design clean from the start rather than carry technical debt forward.

LiveView will subscribe to the event bus and project `%EventBatch{}` into its own local socket state. This is meaningful scope — tracked as a dedicated implementation issue (#118).

All three bare-tuple broadcasts are replaced:
- `{:state_updated, state}` → `%EventBatch{}` on `"game:#{campaign_id}"`
- `:session_ended` → `%Gibbering.Events.Scene.SessionEnded{}` (inside a batch)
- `{:dm_broadcast, text}` / `{:whisper, text}` → see Q5

---

### 2. Canonical set of scene event types

**Decision: 11 events for the initial set (10 from the proposed table + `HPAdjusted`).**

| Event | Triggered by | Key payload fields |
|---|---|---|
| `EntityMoved` | `move_entity` | `entity_id`, `entity_name`, `from`, `to`, `cost_ft` |
| `AttackResolved` | `attack_entity` | `attacker_id`, `attacker_name`, `target_id`, `target_name`, `roll`, `hit?` |
| `DamageDealt` | attack or spell that hits | `target_id`, `target_name`, `amount`, `damage_type`, `new_hp` |
| `ConditionApplied` | attack effect, DM apply | `entity_id`, `entity_name`, `condition_id`, `source_id`, `duration` |
| `ConditionRemoved` | end of duration, save, DM | `entity_id`, `entity_name`, `condition_id`, `reason` |
| `TurnAdvanced` | `end_turn`, `force_end_turn` | `from_entity_id`, `from_entity_name`, `to_entity_id`, `to_entity_name`, `round_number` |
| `PhaseTransitioned` | `transition_phase` | `from_phase`, `to_phase` |
| `SpellCast` | `cast_spell` | `caster_id`, `caster_name`, `spell_key`, `target_id`, `target_name`, `outcome` |
| `ResourceConsumed` | spell slot use, rage | `entity_id`, `entity_name`, `resource_key`, `amount_used`, `remaining` |
| `SessionEnded` | `end_session` | `campaign_id` |
| `HPAdjusted` | DM override | `entity_id`, `entity_name`, `old_hp`, `new_hp`, `reason` |

**`AttackResolved` and `DamageDealt` are separate events.** A miss produces `AttackResolved(hit?: false)` with no `DamageDealt`. This mirrors real 5e mechanics: attack resolution and damage resolution are distinct steps. Subscribers (combat log, animation) need to distinguish them.

**`HPAdjusted` added** as a DM intervention event. DMs can set HP directly outside normal combat flow (see #32). Without it, HP deltas from DM override are invisible to Observability and the event log.

**`VisibilityToggled` deferred** — requires fog-of-war infrastructure not yet designed.

---

### 3. Event envelope and per-event fields

**Decision: Include entity names as denormalized emit-time facts; include `new_hp`; include full causation envelope.**

**Names included as emit-time facts.** Each event carries the names of involved entities as they were at the moment of emission — not as live references. If a name changes after the fact, old event records retain the name they had. This is correct event semantics and makes events self-describing for observability, audit logs, and display without requiring a catalog join.

**`new_hp` in `DamageDealt`:** Include it. Post-damage HP is a fact about the event outcome, authoritative at emit time (SceneServer holds this state). Every subscriber (HP bar rendering, combat log, observability) needs it immediately. Omitting it forces all subscribers to track cumulative prior state themselves.

**`causation_id` and `correlation_id`:** Required on every event per #106 and #111:
- `correlation_id` — the user action (command) that initiated the cascade. All events in a batch share it.
- `causation_id` — the direct cause of this specific event within the cascade (the preceding event's `event_id`, or the command id for the first event).

**`sequence_number`:** Per-batch integer. Orders events within a single `%EventBatch{}`.

**`schema_version`:** Reserved in the envelope. Full versioning design deferred to brainstorm #16 — this is a significant design concern that warrants its own discussion before implementation.

**Canonical event envelope** (applied to every scene event struct):
```
event_id          :: UUID
event_type        :: atom
schema_version    :: integer   ← reserved; versioning policy TBD in brainstorm #16
occurred_at       :: DateTime
correlation_id    :: UUID
causation_id      :: UUID
sequence_number   :: non_neg_integer
payload           :: event-specific fields (names + IDs as above)
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

A single command may produce a causally ordered event cascade (e.g. `attack_entity` → `[AttackResolved, DamageDealt, ConditionApplied]`). Emitting individual PubSub messages loses causal order and forces every subscriber to reassemble the chain themselves. `%EventBatch{}` carries the full causal chain atomically:
- Animation sequencer iterates `batch.events` in order.
- Event log stores the batch as one atomic entry.
- Observability iterates events for metric counters.
- `EventBus` exposes `broadcast_batch/2`.

Per-event `batch_id` was rejected: it pushes assembly work to every subscriber.

---

### 5. Fate of `{:dm_broadcast, text}` and `{:whisper, text}`

**Decision: Typed structs on a dedicated notification topic.**

These are not scene-domain events. The polytope treatise (§8.5) explicitly separates Notification events from scene events. Keeping them on the game topic mixes concerns and forces scene subscribers to filter them out.

Typed structs under `Gibbering.Events.Notification.*`:
- `{:dm_broadcast, text}` → `%Gibbering.Events.Notification.BroadcastSent{campaign_id, text, sent_at}`
- `{:whisper, text}` → `%Gibbering.Events.Notification.WhisperDelivered{campaign_id, target_player_id, text, sent_at}`

PubSub topic: `"notifications:#{campaign_id}"` — separate from `"game:#{campaign_id}"`. LiveView subscribes to both.

---

### 6. Module location for event struct definitions

**Decision: `Gibbering.Events.*` — top-level, owned by no single bounded context.**

Per treatise §3.2: "the Published Language is the polytope's shared artifact. No single context should own the event schema definition for events that cross its boundary."

Sub-namespace layout:
```
Gibbering.Events
├── EventBatch              ← batch envelope
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
└── Campaign                ← future: PlayerJoined, SessionStarted, etc.
```

`docs/architecture.md` will reference `Gibbering.Events` as the Published Language registry.

---

## Issues opened

- **#114** — Scene event struct definitions (`Gibbering.Events.Scene.*` + `EventBatch`) — **high priority, unblocks #108/#115/#116**
- **#115** — Notification event structs + dedicated topic migration
- **#116** — SceneServer: replace bare-tuple broadcasts with typed `%EventBatch{}`
- **#117** — Architecture doc: document `Gibbering.Events` as Published Language registry
- **#118** — LiveView event projection (scoped; depends on #116)
- **Brainstorm #16** — Schema versioning design (must settle before #114 is fully implemented)
