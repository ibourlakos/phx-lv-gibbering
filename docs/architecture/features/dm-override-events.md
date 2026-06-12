# DM Override Events

The DM can override any game state in a running session. The design constraint is that the
event log is **append-only** — a DM "undo" is a compensating event, not a deletion.

## Taxonomy: first-class types, not a shared wrapper

DM override events follow the same Published Language convention as scene events — each is a
named struct, not a generic `%DMOverride{type: :foo, payload: ...}` wrapper. The discriminator
approach is the stringly-typed anti-pattern that `Gibbering.Events.*` exists to replace.

**Reuse existing event types where the semantic matches:**

| DM action | Event type | Distinguishing field |
|---|---|---|
| Adjust HP | `%HPAdjusted{}` | `actor: :dm` |
| Remove condition | `%ConditionRemoved{}` | `actor: :dm` |
| Apply condition / active effect | `%ConditionApplied{}` | `actor: :dm` |
| Consume resource | `%ResourceConsumed{}` | `actor: :dm` |

**New first-class types for DM-only mechanics (to be defined in a follow-on issue):**

| Event type | Purpose |
|---|---|
| `%StatOverridden{}` | Set an arbitrary stat value directly |
| `%InitiativeReordered{}` | Rewrite the turn-order list |
| `%RollForced{}` | Override the result of a roll |
| `%DeathSavesSkipped{}` | Bypass death save tracking for an entity |

## Actor field and audit trail

All scene event structs will gain three additive nullable fields (tracked as a follow-on issue):

```
actor:       :system | :dm          # default :system
dm_user_id:  String.t() | nil       # nil for system events
dm_reason:   String.t() | nil       # optional narrative justification
```

`dm_user_id` is non-nil for every DM-initiated event. `dm_reason` is optional but encouraged.
Both are additive changes (safe per the additive-only discipline — `:system` / `nil` defaults
are truthful for all prior events).

## Pipeline interaction: through SceneServer, not around it

DM overrides are commands submitted to `SceneServer`, not out-of-band state mutations. The
SceneServer produces typed events exactly as it does for player commands. The predicate
evaluator and rule pipeline see the resulting events and apply them normally.

Example: DM granting Advantage for narrative reasons → `SceneServer.dm_apply_condition/3` →
`%ConditionApplied{condition: :advantage, actor: :dm, dm_user_id: ..., dm_reason: ...}`.
The predicate evaluator sees a `ConditionApplied` event and applies it — no special path.

Exception: `%StatOverridden{}`, `%RollForced{}`, and `%DeathSavesSkipped{}` have no
rule-mediated analog. They directly mutate state inside SceneServer without predicate
evaluation. They still go through SceneServer (single-writer contract preserved) and are
emitted as typed events in the batch.

## God-mode scope

No engine-level prohibition on DM commands. SceneServer honours all DM commands without
guard conditions. The UI may prompt for confirmation on high-impact actions (reducing HP to 0,
`%DeathSavesSkipped{}`, `%InitiativeReordered{}` mid-round) but that is a presentation
concern. Every override is recorded in the event log.

## Player visibility

DM override events are included in the `%EventBatch{}` broadcast to all subscribers.
`GameLive` renders them in the combat log with a "DM" badge. `dm_reason` is omitted from
the player view — it is DM-view only. This follows the existing `WhisperDelivered` guard
pattern where `GameLive` guards on `target_player_id == current_user.id`.

## Implementation follow-on

Two issues required before any DM override commands are wired up:
1. Add `actor`, `dm_user_id`, `dm_reason` fields to all `Gibbering.Events.Scene.*` structs
   (additive schema change — bump `@current_version` on each struct)
2. Define the four new DM-only event types listed above
3. Add DM command handlers to `SceneServer` that produce the appropriate events
