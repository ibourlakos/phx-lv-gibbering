# #36 · Scene phase state machine in `SceneServer`

**Status:** closed
**Closed:** 2026-06-05
**Opened:** 2026-06-05
**Priority:** high
**Tags:** architecture, rules

`GameServer` is a bare data bag with no explicit scene phase. This means the
engine cannot distinguish exploration actions from combat turns, cannot model
initiative rolling as a distinct state, and cannot cleanly reject events that
are invalid for the current phase.

The server should be renamed `SceneServer` and gain a `phase` field that drives
event generation rules and post-resolution transition checks.

Valid phases: `:lobby | :exploration | :initiative_rolling | :in_combat | :paused`

Phase transitions are themselves events in the event log.
An attack in `:exploration` resolves normally and then triggers a transition
check — it does NOT require `:in_combat` to execute.

**Acceptance criteria**
- [ ] `Gibbering.Engine.GameServer` renamed to `Gibbering.Engine.SceneServer`; all call sites updated
- [ ] `Engine.State` gains `phase :: scene_phase()` (default `:lobby`) and `previous_phase :: scene_phase() | nil`
- [ ] `SceneServer` exposes `transition_phase/2` — validates the transition and appends a phase-change event to the log
- [ ] Valid transitions enforced: `:lobby → :exploration`, `:exploration → :initiative_rolling`, `:initiative_rolling → :in_combat`, `:in_combat → :exploration`, `any → :paused`, `:paused → previous_phase`
- [ ] DM can force any transition (no validation for DM-originated calls)
- [ ] `mix precommit` passes
