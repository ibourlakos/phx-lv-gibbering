# #119 · Scene event struct definitions — Gibbering.Events.* Published Language registry

**Status:** open
**Opened:** 2026-06-09
**Priority:** high
**Tags:** architecture, rules

Define the typed event structs that form the Published Language for the scene context. This is the schema-specification step of the event schema mini-cycle (see #106) and directly unblocks #108 (EventBus behaviour) and #116 (SceneServer coexist pattern).

**Module layout:**
```
Gibbering.Events
├── EventBatch          ← batch envelope (command, batch_id, correlation_id, occurred_at, events)
└── Scene
    ├── EntityMoved
    ├── AttackResolved
    ├── DamageDealt
    ├── ConditionApplied
    ├── ConditionRemoved
    ├── TurnAdvanced
    ├── PhaseTransitioned
    ├── SpellCast
    ├── ResourceConsumed
    ├── SessionEnded
    └── HPAdjusted
```

**Canonical event envelope fields** (all scene event structs include these):
- `event_id` — UUID
- `event_type` — atom
- `schema_version` — integer
- `occurred_at` — DateTime
- `correlation_id` — UUID (the user action that triggered the cascade)
- `causation_id` — UUID (the preceding event's `event_id`, or command id for first event)
- `sequence_number` — non_neg_integer (position within the batch)

**Field conventions:**
- IDs only (no denormalized names — derivable from Content catalog)
- `DamageDealt` includes `new_hp` (authoritative post-damage HP at emit time)

**References:**
- Brainstorm #15 — full field specs per event type
- Issue #106 (event envelope spec)
- Issue #108 (EventBus behaviour — unblocked by this issue)
- Issue #111 (batch emission — depends on EventBatch struct)
- `docs/papers/polytope-architecture.md` §3.2, §7.1, §8.5

**Acceptance criteria**
- [ ] `Gibbering.Events.EventBatch` struct defined with: `batch_id`, `command`, `correlation_id`, `occurred_at`, `events`
- [ ] All 11 scene event structs defined under `Gibbering.Events.Scene.*` with canonical envelope + payload fields
- [ ] Each struct has a `@type t()` typespec
- [ ] A `Gibbering.Events` module documents the namespace as the Published Language registry
- [ ] Unit tests for struct construction (field presence, default values)
- [ ] `docs/architecture.md` references `Gibbering.Events` as the Published Language registry
