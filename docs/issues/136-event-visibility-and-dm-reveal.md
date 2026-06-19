# #136 · Event visibility taxonomy + LogEntryRevealed / LogEntryHidden event structs

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-20
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
- [x] `visibility` field (`t :: :public | :dm_only | :revealed`) added to the canonical event envelope typespec
- [x] Default visibility assigned correctly per event type at emit time in `SceneServer` / `Rules`
- [x] `Gibbering.Events.Scene.LogEntryRevealed` struct defined with `original_event_id`, `revealed_at`, envelope fields
- [x] `Gibbering.Events.Scene.LogEntryHidden` struct defined with `original_event_id`, `hidden_at`, envelope fields
- [x] Both structs implement `Gibbering.Events.Upcaster` at v1
- [x] Player feed projection folds `LogEntryRevealed` / `LogEntryHidden` in log order to derive effective visibility
- [x] DM log renders eye-icon reveal affordance on `:dm_only` events
- [x] Clicking reveal/hide affordance emits the correct event and updates player feeds via PubSub in real time
- [x] Revealed events render with a DM-disclosure marker in the player feed
- [x] Unit tests for projection fold logic (revealed → hidden → re-revealed sequence)
- [x] `mix precommit` exits 0

**Implementation notes**
- `visibility: :public | :dm_only | :revealed` added to all 14 existing scene event structs (on this branch; `RollRequired` lives on the unmerged WP-P branch and will get the field when that PR lands)
- `HPAdjusted` defaults to `:dm_only` (DM god-mode action); `AttackResolved` set to `:dm_only` at emit time when attacker is a non-hero
- `Gibbering.Events.EventFeedProjection` — pure fold module; `fold/1` derives `%{event_id => :revealed | :dm_only}`; `player_visible/1` returns `[{event, effective_visibility}]` pairs
- SceneServer: `reveal_log_entry/2` and `hide_log_entry/2` public API + `handle_call` handlers; emit `LogEntryRevealed` / `LogEntryHidden` into the batch
- GameLive: `@event_log` assign accumulates typed event structs from each `%EventBatch{}`; DM log panel shows all events with eye-icon toggle on `:dm_only` entries; player Events panel shows `EventFeedProjection.player_visible/1` output with 👁 marker on `:revealed` events
