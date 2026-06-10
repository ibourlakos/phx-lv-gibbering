# #116 · SceneServer: replace bare-tuple broadcasts with typed %EventBatch{}

**Status:** closed
**Opened:** 2026-06-09
**Closed:** 2026-06-10
**Priority:** medium
**Tags:** architecture, rules

Remove all bare-tuple broadcasts from `SceneServer` and replace them with typed `%EventBatch{}` emission per command. This is a clean break — no coexistence with `{:state_updated, state}`.

**Broadcasts to remove:**
- `{:state_updated, state}` — replaced by `%EventBatch{}`
- `:session_ended` — replaced by a batch containing `%Scene.SessionEnded{}`
- `{:dm_broadcast, text}` and `{:whisper, text}` — moved to notification topic in #115

**Implementation:**
Each command handler in `SceneServer` returns `{new_state, [%Event{...}]}` (per #111's acceptance criteria). SceneServer wraps the event list into a `%EventBatch{}` and broadcasts it via `EventBus` (or `Phoenix.PubSub` directly until #108 lands).

Envelope fields per event:
- `correlation_id` — UUID generated per command (shared by all events in the batch)
- `causation_id` — preceding event's `event_id`, or `correlation_id` for the first event
- `sequence_number` — 0-indexed position within the batch
- `occurred_at` — DateTime at command execution

**LiveView:** removing `{:state_updated, state}` breaks LiveView rendering. The LiveView projection is tracked separately in #118 and must land in the same PR or immediately after.

**References:**
- Brainstorm #15 (Q1 and Q4 decisions)
- Issue #119 (event struct definitions — must land first)
- Issue #115 (notification topic migration — coordinate removal of dm_broadcast)
- Issue #118 (LiveView projection — must ship with or immediately after this)
- Issue #108 (EventBus behaviour — route through it once available)
- Issue #111 (Event Aggregator pattern — command handler return signature)

**Acceptance criteria**
- [x] All `Phoenix.PubSub.broadcast` calls in `SceneServer` that emit bare tuples are removed
- [x] Every command handler builds and broadcasts a `%EventBatch{}` with typed events
- [x] `{:state_updated, state}` is gone entirely
- [x] `:session_ended` bare atom is gone; replaced by a `SessionEnded` event inside a batch
- [x] `{:dm_broadcast, text}` removed (handled by #115)
- [x] At least one integration test verifies `%EventBatch{}` receipt on a move command
- [x] Existing tests pass (LiveView tests updated as part of #118)
