# #111 · Event cascade batch emission — Event Aggregator pattern

**Status:** closed
**Opened:** 2026-06-07
**Closed:** 2026-06-10
**Priority:** medium
**Tags:** discovery, architecture

The polytope treatise (§9, Integration dimension: Event Aggregator; §7.3, causation_id and correlation_id) establishes that a single command should produce a causally ordered event batch, not a sequence of individual unrelated broadcasts.

Example: an `AttackDeclared` command produces the cascade `[AttackResolved, DamageDealt, ConditionApplied]`. These are not independent events — they are causally linked. The animation sequencer, the combat log, the audit trail, and any spectator replay all depend on preserving this causal structure.

The required pattern:
1. A command arrives at SceneServer
2. SceneServer processes the command against current state
3. SceneServer builds an ordered list of typed events with causation chains:
   - All events share a `correlation_id` (the top-level user action)
   - Each event carries a `causation_id` pointing to its preceding cause in the cascade
4. The entire batch is emitted atomically through the EventBus after the command completes successfully
5. Subscribers receive the full batch (or individual events in causal order) — never a partial cascade

This is a discovery issue: design the batch structure, the emission API, and how subscribers receive and process batches. The event envelope fields from #106 (§7.3 of the treatise) apply directly here.

**References**
- `docs/papers/polytope-architecture.md` §7.3 (causation_id, correlation_id in event envelope), §9 (Event Aggregator in Integration dimension patterns), §5.1 (causality as first-class concern)
- Issue #106 (event schema methodology — envelope spec)
- Issue #110 (SceneServer single writer — the actor that produces the batch)
- Issue #108 (EventBus behaviour — the port through which the batch is emitted)

**Acceptance criteria**
- [x] A command handler in SceneServer returns `{new_state, [%Event{...}]}` — a batch of typed events, not individual broadcast calls
- [x] Each event in the batch carries `causation_id` (the event that caused it in this cascade, or the command id for the first event) and `correlation_id` (the user action that initiated the whole cascade)
- [x] The EventBus behaviour includes a `broadcast_batch/2` or equivalent that emits the batch in causal order
- [x] Subscribers can reconstruct causal order from the `causation_id` chain without relying on arrival order
- [x] The design is documented in `docs/architecture.md` or a dedicated subsection
