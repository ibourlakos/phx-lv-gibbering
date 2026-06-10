# Brainstorm #16 — Event schema versioning design

**Status:** open

## Context

Brainstorm #15 settled the initial Published Language for scene events (`Gibbering.Events.*`) and reserved a `schema_version` field on every event struct. Before issue #114 (struct definitions) can be fully implemented, the versioning design must be settled.

The driving analogy from the project: **think of event schema versioning like logical database schema design**. A DB table has a schema; migrations are versioned; you cannot safely rename or drop a column without a migration window. Event structs share these properties — with the added complexity that events may be persisted in an event log and replayed later by future code.

**Current state:** bare tuples, no versioning concern at all. This is the greenfield moment to design it right.

**Why this matters now:** `schema_version` appears on every struct. If its meaning and policy aren't settled before #114, we'll implement it wrong and it will be a breaking change to fix later — which is exactly the problem it's supposed to prevent.

**Cross-references:** #106 (event schema design methodology), #114 (struct definitions — blocked on this), brainstorm #15.

---

## Decisions

### Q1 — `schema_version` semantics: per-event-type integer

Each event struct carries its own independent `schema_version` integer starting at `1`. `DamageDealt` and `EntityMoved` version independently. This matches the industry consensus in event sourcing (EventStore, Axon, Commanded) and the DB-analogy: each table has its own migration history. It is the most precise identifier when deserialising persisted events for replay and upcasting.

### Q2 — Breaking changes: additive-only discipline

Events are append-only contracts. The rules:
- **Non-breaking (safe):** Adding a field with a default that is truthful for every prior event — i.e. no subscriber would behave incorrectly on an event carrying that default.
- **Breaking:** Renaming a field, removing a field, changing a field's type, tightening a constraint, or adding a field where no truthful default exists for prior events.
- **The additive-only rule:** Once a field is published, it is never renamed or removed. Breaking changes produce a new event type, not a new version of the old one. When in doubt, treat an addition as breaking and bump the version.

The truthfulness test cannot be evaluated by the producer alone — it requires knowing what each subscriber would do with the default. In a system where the consumer set is not fully observable (microservices, future consumers), the conservative default is: if the default's correctness cannot be guaranteed for all possible consumers, it is a breaking change.

**Noted for future implementation:** two architectural patterns to enforce these guarantees at scale are recorded in `docs/papers/polytope-architecture.md` §7.4 and §15.2: (1) a subscriber contract port (`contract/0` callback on `EventBus.Subscriber` behaviour), and (2) a `SchemaViolation` meta-event emitted by subscribers at runtime when they receive an unrecognised schema version.

---

## Open questions

### 1. What does `schema_version` mean on a struct?

Options:
- **Per-struct integer** — each event type has its own version number. `DamageDealt` starts at `1`; when it gains a field it becomes `2`. Independent per type.
- **Global registry integer** — a single version number covers the entire Published Language. Any change to any event type bumps the global version.
- **Struct module versioning** — no `schema_version` field; instead, breaking changes produce a new module: `Events.Scene.DamageDealt.V2`. Consumers pattern-match on the module name.

Which model fits a monorepo BEAM application best? What are the tradeoffs when a persistent event log is added later?

### 2. What constitutes a breaking change?

In DB terms: adding a NOT NULL column without a default is breaking; adding a nullable column is not. What is the equivalent rule for event structs?

Candidates:
- **Non-breaking (safe):** adding a field with a default value; loosening a type constraint
- **Breaking:** renaming a field; removing a field; changing a field's type; adding a required field with no default
- **Ambiguous:** adding a field whose absence is semantically significant (e.g. `critical_hit?: boolean` — a subscriber that doesn't see it assumes false, but that assumption may be wrong)

What is the formal rule?

### 3. How does a consumer know which version it's handling?

If `schema_version` is a field, consumers check `event.schema_version` and branch. But:
- In a monorepo with compile-time structs, the struct definition IS the version. Mismatches are compile errors, not runtime surprises.
- In a persistent event log, old persisted events (as raw maps) may not match the current struct. A decoder/migration layer is needed.

Does the monorepo context change the answer? Does version checking belong at the struct level, the decoder level, or both?

### 4. Migration windows

In DB schema design, you run old and new code simultaneously during a migration window. For events:
- **In-process bus:** no persistence, no old code — a deploy atomically replaces all producers and consumers. No migration window needed.
- **Persistent event log (future):** old events on disk must be readable by new code. A migration function (or versioned decoders) is needed.

Should the design anticipate the event log now (add decoder infrastructure) or keep it minimal and extend when the event log is implemented?

### 5. Versioning granularity: per-event-type or per-namespace?

Versioning each of the 11 event types independently is fine-grained but produces 11 independent version numbers to track. Versioning the entire `Gibbering.Events.Scene` namespace as a unit is simpler but means any change in any event bumps the whole namespace.

Which granularity fits the "DB logical design" analogy? (A DB schema has one version per migration, not one per table.)

---

## Issues to open after settling

_(Fill in after decisions are made)_

- Update `schema_version` field spec in #114 (struct definitions)
- Any decoder/migration infrastructure as a separate issue if anticipated now
- Update event schema methodology in #106 (versioning policy section)
