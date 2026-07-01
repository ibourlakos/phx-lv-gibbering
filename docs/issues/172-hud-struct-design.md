# #172 · HUD struct design — `%GibberingEngine.HUD{}` and `Ruleset.hud/1` callback

**Status:** open
**Opened:** 2026-07-01
**Priority:** medium
**Tags:** architecture, discovery, rendering, ui

Design the engine's HUD concern: a pure data struct the Ruleset populates after each state change, which the web layer renders without game-specific knowledge.

Gated on WP-S (#168–#171) completing — the struct lives in `gibbering_engine`, which doesn't exist until Phase 2b.

---

## Context

`GameLive` currently reads raw `Engine.State` and `ruleset_state` directly to decide what HUD elements to render: action buttons, dice roll prompts, initiative panel, valid-move overlay, valid-target highlights, condition overlays, log feed. This tightly couples the web layer to both the engine struct layout and D&D-specific ruleset fields.

The HUD concern (established in brainstorm #34) is the engine's mechanism for the Ruleset to declare what the web layer should show — without the web layer needing to know what game it's running.

---

## Questions to answer

- What is the minimal shape of `%GibberingEngine.HUD{}`? Proposed slots:
  - `action_bar: [%HUD.Action{}]` — available player actions (label, event key, enabled?)
  - `overlays: [%HUD.Overlay{}]` — tile highlights (valid moves, valid targets, AoE previews)
  - `prompts: [%HUD.Prompt{}]` — blocking input requests (dice roll, confirmation gate)
  - `status_strip: [%HUD.StatusItem{}]` — per-actor status indicators (replaces ConditionBadge in the web layer; Tales populates from D&D conditions)
  - `panels: %{left: term(), right: term()}` — inspection / event feed panel content (or keep panels in web layer state?)

- Where is HUD computed? Options:
  - (A) `hud/1` is a new callback on the `GibberingEngine.Ruleset` behaviour — called by `SceneServer` after every state transition; HUD is stored in `Engine.State` or returned alongside the new state
  - (B) HUD is computed by the web layer calling a Tales helper that reads `Engine.State` + `ruleset_state` — no engine callback needed; engine stays unaware of HUD
  - (C) HUD is a LiveView concern only — no engine or Tales struct at all; just move the GameLive logic into better-named helpers

- Does HUD vary by viewer role (player vs DM)? A DM's action bar contains intervention tools; a player's contains character actions. Does the engine pass the viewer's role into `hud/1`, or does the web layer call `hud/1` twice with different role params?

- Does HUD replace or supplement existing `assigns` in GameLive? The socket currently holds `dm_panel`, `panel_subject`, `dm_intervene_entity_id` etc. — do those fold into HUD or stay as ephemeral UI state?

---

## Candidate answer to validate

Option (B): HUD is computed by the web layer, not the engine. `GibberingEngine.HUD` is a pure data struct defined in the engine (so any game's web layer can use the same shape), but it is populated by a `GibberingTales.HUD` helper module — not via a `SceneServer` callback. The engine stays unaware of HUD entirely; the struct is just a shared vocabulary.

This avoids adding a new required callback to the Ruleset behaviour (which all future rulesets must implement) for something that is inherently a presentation concern.

Ephemeral UI state (`dm_panel`, `panel_subject`) stays in LiveView socket assigns — these are interaction state, not game state.

---

## Acceptance criteria

- [ ] `%GibberingEngine.HUD{}` struct fields are specified and justified
- [ ] Computation site decision (engine callback vs. Tales helper vs. LiveView) is made and documented
- [ ] Role-gating approach (player vs DM HUD) is decided
- [ ] Boundary between HUD data and ephemeral LiveView state is drawn
- [ ] At least one implementation issue is derived (#173 or replacement)
