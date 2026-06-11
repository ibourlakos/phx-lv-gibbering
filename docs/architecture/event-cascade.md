# Event Cascade Batch Emission

Every command that mutates scene state produces a causally ordered `%EventBatch{}` emitted
atomically after the command succeeds. Subscribers always receive the full batch — never a
partial cascade. This satisfies §5.1 (causality as first-class concern) and §9 (Event
Aggregator) of the polytope paper.

## Batch structure

```
%EventBatch{
  batch_id:       UUID,        # unique per broadcast
  command:        atom,        # :move_entity, :attack, :end_turn, …
  correlation_id: UUID,        # shared by all events in this batch
  occurred_at:    DateTime,    # timestamp at command execution
  state_snapshot: %State{},   # post-command state; LiveView projects from this
  events:         [%Scene.*{}, …]
}
```

## Per-event envelope fields

Each event struct in `Gibbering.Events.Scene.*` carries:

| Field | Type | Meaning |
|---|---|---|
| `event_id` | UUID | Unique identifier for this event |
| `correlation_id` | UUID | Top-level user action (shared across the batch) |
| `causation_id` | UUID | Preceding cause: `correlation_id` for the first event, `event_id` of the prior event for all others |
| `sequence_number` | integer | 0-indexed position within the batch |
| `occurred_at` | DateTime | Timestamp at command execution |

## Causation chain

```
command (correlation_id = C)
  ├─ event[0]  event_id=E0, causation_id=C   (caused by the command itself)
  ├─ event[1]  event_id=E1, causation_id=E0  (caused by event[0])
  └─ event[2]  event_id=E2, causation_id=E1  (caused by event[1])
```

Subscribers can reconstruct causal order from the `causation_id` chain without relying on
arrival order.

## Command → event cascade examples

| Command | Events emitted |
|---|---|
| `move_entity` | `[%EntityMoved{}]` |
| `attack_entity` (hit) | `[%AttackResolved{}, %DamageDealt{}, %TurnAdvanced{}]` |
| `attack_entity` (miss) | `[%AttackResolved{}, %TurnAdvanced{}]` |
| `cast_spell` (hit) | `[%SpellCast{}, %DamageDealt{}, %TurnAdvanced{}]` |
| `end_turn` / `force_end_turn` | `[%TurnAdvanced{}]` |
| `transition_phase` / `resume_session` | `[%PhaseTransitioned{}]` |
| `end_session` | `[%SessionEnded{}]` |
| `dm_apply_condition` | `[%ConditionApplied{}]` |
| `dm_adjust_hp` | `[%HPAdjusted{}]` |
| UI-only commands (select, reload, order, visibility) | `events: []` (snapshot only) |

## state_snapshot and late-join

`batch.state_snapshot` carries the complete post-command `%Engine.State{}`. LiveView
projects it directly into `socket.assigns.game_state`. This means:

- Commands without typed event mappings (e.g. `select_entity`, `reload_entities`) still
  trigger a full board re-render via the snapshot.
- A LiveView that mounts after events have already been emitted receives the current state
  from `SceneServer.get_state/1` at mount time (not from replaying the event log), so
  late-join and reconnect scenarios render correctly.

The snapshot is the pragmatic short-circuit for the CQRS read model described in
[cqrs-read-model.md](cqrs-read-model.md). When per-event projection functions exist for all
event types, the snapshot becomes an optional optimisation rather than a necessity.
