# #136 · Event visibility taxonomy + LogEntryRevealed / LogEntryHidden event structs

**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** architecture, gameplay, ui

Extends the Published Language (issue #119, closed) with the event visibility
mechanism designed in brainstorm #18. Prerequisite for the player event feed
(issue #137).

## Design decisions (from brainstorm #18)

**`visibility` field** added to the canonical scene event envelope:

| Value | Meaning |
|---|---|
| `:public` | Shown in both DM log and player feed |
| `:dm_only` | DM log only; players see nothing |
| `:revealed` | Was `:dm_only`; DM explicitly pushed it to the player feed |

Default visibility is determined at emit time by event type (see brainstorm #18
§8 visibility taxonomy table for the full mapping).

**Two new event structs** in `Gibbering.Events.Scene`:

```elixir
%Events.Scene.LogEntryRevealed{ original_event_id: uuid(), revealed_at: DateTime.t() }
%Events.Scene.LogEntryHidden{   original_event_id: uuid(), hidden_at:   DateTime.t() }
```

The event log is append-only. `LogEntryRevealed` does not mutate the original event —
visibility is a derived property of the projection. `LogEntryHidden` can only retract
a previously revealed event; it cannot suppress a naturally `:public` event.

**DM UX:** each `:dm_only` line in the DM log has a reveal affordance (eye icon).
Clicking emits `LogEntryRevealed`; the event appears in connected player feeds in real
time. A second click emits `LogEntryHidden` and removes it from player feeds.

**Revealed rendering:** revealed events carry a visual DM-disclosure marker in the
player feed so players know the DM chose to share it.

**Acceptance criteria**
- [ ] `visibility` field (`t :: :public | :dm_only | :revealed`) added to the canonical event envelope typespec
- [ ] Default visibility assigned correctly per event type at emit time in `SceneServer` / `Rules`
- [ ] `Gibbering.Events.Scene.LogEntryRevealed` struct defined with `original_event_id`, `revealed_at`, envelope fields
- [ ] `Gibbering.Events.Scene.LogEntryHidden` struct defined with `original_event_id`, `hidden_at`, envelope fields
- [ ] Both structs implement `Gibbering.Events.Upcaster` at v1
- [ ] Player feed projection folds `LogEntryRevealed` / `LogEntryHidden` in log order to derive effective visibility
- [ ] DM log renders eye-icon reveal affordance on `:dm_only` events
- [ ] Clicking reveal/hide affordance emits the correct event and updates player feeds via PubSub in real time
- [ ] Revealed events render with a DM-disclosure marker in the player feed
- [ ] Unit tests for projection fold logic (revealed → hidden → re-revealed sequence)
- [ ] `mix precommit` exits 0
