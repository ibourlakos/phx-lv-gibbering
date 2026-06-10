# #118 · LiveView event projection from %EventBatch{}

**Status:** closed
**Opened:** 2026-06-10
**Closed:** 2026-06-10
**Priority:** medium
**Tags:** architecture, ui

With `{:state_updated, state}` removed (#116), LiveView can no longer re-render the game board from a full state snapshot. It must instead subscribe to the event bus, receive `%EventBatch{}` messages, and project them into its own local socket state.

**Scope:**
- Subscribe `GameLive` to `"game:#{campaign_id}"` (already done) and handle `%EventBatch{}` in `handle_info/2`
- Maintain a local state projection in socket assigns: apply each event in `batch.events` to the current assigns in order
- Each scene event type maps to a specific projection function (e.g. `EntityMoved` updates entity position, `DamageDealt` updates entity HP, `TurnAdvanced` updates initiative order)
- Subscribe `GameLive` to `"notifications:#{campaign_id}"` and handle `%BroadcastSent{}` / `%WhisperDelivered{}`

**Design questions to resolve before implementation:**
- Does LiveView maintain a full local copy of `Engine.State`-equivalent assigns, or a slimmer display model?
- How are late-join / reconnect scenarios handled (LiveView mounts after events have already been emitted)?

**References:**
- Brainstorm #15 (Q1 decision — Replace strategy)
- Issue #116 (SceneServer typed broadcast — prerequisite)
- Issue #115 (notification topic — coordinate subscription)
- `docs/papers/polytope-architecture.md` §9 (CQRS — LiveView assigns as informal read model)

**Acceptance criteria**
- [x] `GameLive` no longer has a `handle_info({:state_updated, state}, ...)` clause
- [x] `GameLive` handles `%EventBatch{}` and projects each contained event into socket assigns
- [x] `GameLive` handles `%BroadcastSent{}` and `%WhisperDelivered{}` from the notifications topic
- [x] The game board renders correctly after a move, attack, and turn-advance command
- [x] Late-join / reconnect renders the current scene state (not a blank board)
- [x] All existing GameLive integration tests pass with updated event handling
