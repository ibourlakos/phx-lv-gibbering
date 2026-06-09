# #116 · SceneServer: coexist typed event broadcast pattern

**Status:** open
**Opened:** 2026-06-09
**Priority:** medium
**Tags:** architecture, rules

**Blocked by:** #114 (event struct definitions must exist first)

Update `SceneServer` to emit a typed `%EventBatch{}` per command alongside the existing `{:state_updated, state}` broadcast. This implements the "coexist" transition strategy decided in brainstorm #15:

- `%EventBatch{}` on `"game:#{campaign_id}"` — for Observability, the future event log, spectator feed, animation sequencer, and any subscriber that needs semantics.
- `{:state_updated, state}` on `"game:#{campaign_id}"` — **kept** as a Web Adapter convenience projection until LiveView is migrated to project from typed events. Labelled explicitly as transitional.

**Implementation notes:**
- Each command handler in `SceneServer` should produce `{new_state, [%Event{...}]}` (per #111's acceptance criteria), then wrap into a `%EventBatch{}` and broadcast via `EventBus` (or `Phoenix.PubSub` directly until #108 is implemented).
- `correlation_id` on the batch = UUID generated per command.
- `causation_id` on the first event = command id (or correlation_id). Subsequent events in a cascade point to the preceding event's `event_id`.
- `sequence_number` is assigned sequentially within the batch (0-indexed).
- `{:state_updated, state}` removal is tracked as a follow-up once LiveView projection is implemented.

**References:**
- Brainstorm #15 (Q1 and Q4 decisions)
- Issue #114 (event struct definitions — must land first)
- Issue #108 (EventBus behaviour — when available, route batch through it)
- Issue #111 (Event Aggregator pattern — command handler return signature)

**Acceptance criteria**
- [ ] Every `SceneServer` command handler builds a `%EventBatch{}` with the correct typed events
- [ ] `%EventBatch{}` is broadcast on the game topic after each successful command
- [ ] `{:state_updated, state}` continues to broadcast (unchanged) for LiveView compatibility
- [ ] A `# TODO: remove once LiveView projects from EventBatch` comment marks the `{:state_updated, state}` broadcast
- [ ] Existing LiveView tests continue to pass
- [ ] At least one integration test verifies the `%EventBatch{}` is received by a test subscriber on a move command
