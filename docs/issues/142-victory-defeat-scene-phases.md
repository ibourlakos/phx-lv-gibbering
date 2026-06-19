# #142 · Victory and defeat scene phases + auto-trigger

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-19
**Priority:** high
**Tags:** architecture, gameplay, rules

## Context

The scene phase state machine (closed #36) defines phases up to `:in_combat` and
`:paused` but has no terminal combat outcome phases. There is no mechanism for the
engine to declare the encounter won or lost, and no event players receive when combat
ends.

A minimum playable campaign requires the engine to transition into `:victory` or
`:defeat` and broadcast that fact so players can see an outcome screen.

## What needs to happen

1. Add `:victory` and `:defeat` to the `scene_phase()` type in `Engine.State`.
2. Valid transitions: `:in_combat → :victory`, `:in_combat → :defeat`. Both are terminal
   (no further phase transitions except an explicit DM reset to `:lobby`).
3. Auto-trigger check: after every entity death, evaluate:
   - All entities with `entity_type: :enemy` dead → `:victory`
   - All entities with `entity_type: :player` dead → `:defeat`
4. DM can force either transition via `transition_phase/2` regardless of entity state
   (same god-mode rule as existing forced transitions).
5. The resulting phase-change event must be a typed `%Events.PhaseChanged{}` struct
   carrying `previous_phase` and `new_phase`.
6. Append `%Events.PhaseChanged{new_phase: :victory | :defeat}` to the event log;
   existing `SceneServer` broadcast mechanism delivers it to all subscribers.

## Out of scope

- The player-facing outcome screen (see #143).
- DM "reset to lobby" control (that is part of DM session controls — extend #93 scope or
  file a follow-on issue when needed).

**Acceptance criteria**
- [x] `:victory` and `:defeat` are valid `scene_phase()` values
- [x] Transitions `:in_combat → :victory` and `:in_combat → :defeat` are accepted by `transition_phase/2`; all other targets from these phases are rejected
- [x] Auto-trigger fires correctly after entity death: all enemies dead → `:victory`; all PCs dead → `:defeat`
- [x] DM can force either transition from `:in_combat` phase
- [x] `%Events.Scene.PhaseTransitioned{}` event emitted and broadcast on each transition
- [x] `mix precommit` passes
