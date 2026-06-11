# #119 · Scene event struct definitions — Gibbering.Events.* Published Language registry

**Status:** closed
**Opened:** 2026-06-09
**Closed:** 2026-06-10
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
- Entity names included as denormalized emit-time facts (not live references)
- `DamageDealt` includes `new_hp` (authoritative post-damage HP at emit time)

**Versioning (settled in brainstorm #16):**
- Each struct declares `@current_version :: integer` (starts at `1`)
- Each struct implements `Gibbering.Events.Upcaster` behaviour: `upcast(from_version, raw_map) :: raw_map`
- At v1, all upcasters are identity functions — infrastructure established, no-op until a field is added
- `Gibbering.Events.Decoder` module: `decode(module, raw_map) :: {:ok, struct} | {:error, term}` — chains upcasters from `raw_map["schema_version"]` to `module.current_version`, then constructs the struct
- Additive-only discipline: fields are never renamed or removed once published; additions require a truthful default for all prior events or bump the version

**References:**
- Brainstorm #15 — full field specs per event type
- Brainstorm #16 — versioning policy
- Issue #106 (event envelope spec)
- Issue #108 (EventBus behaviour — unblocked by this issue)
- Issue #111 (batch emission — depends on EventBatch struct)
- `docs/papers/polytope-architecture.md` §3.2, §7.1, §7.4, §7.5, §8.5, §15.2

**Acceptance criteria**
- [ ] `Gibbering.Events.EventBatch` struct defined with: `batch_id`, `command`, `correlation_id`, `occurred_at`, `events`
- [ ] All 11 scene event structs defined under `Gibbering.Events.Scene.*` with canonical envelope + payload fields
- [ ] Each struct declares `@current_version 1` and implements `Gibbering.Events.Upcaster`
- [ ] `Gibbering.Events.Upcaster` behaviour defined with `upcast(from_version :: integer, raw_map :: map) :: map`
- [ ] `Gibbering.Events.Decoder` module implemented with `decode(module, raw_map) :: {:ok, struct} | {:error, term}`
- [ ] Each struct has a `@type t()` typespec
- [ ] A `Gibbering.Events` module documents the namespace as the Published Language registry
- [ ] Unit tests for struct construction (field presence, default values)
- [ ] Unit tests for `Decoder.decode/2` at current version (round-trip: struct → map → struct)
- [ ] `docs/architecture.md` references `Gibbering.Events` as the Published Language registry
