# #172 · HUD struct design — `%GibberingEngine.HUD{}` and `Ruleset.hud/1` callback

**Status:** closed
**Opened:** 2026-07-01
**Closed:** 2026-07-02
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

---

## Decision record (closed 2026-07-02)

**Option B adopted.** `GibberingEngine.HUD` is a pure data struct (shared vocabulary) defined in `gibbering_engine`. It is populated by a `GibberingTalesWeb.HUD.build/2` helper in `gibbering_tales_web` — not via a `SceneServer` callback and not in `gibbering_tales`.

**Dependency constraint:** The issue initially proposed `GibberingTales.HUD` in `gibbering_tales`, but `Engine.State` (the runtime struct that `build/2` reads) lives in `gibbering_tales_web`. Moving `Engine.State` to `gibbering_tales` is out of scope for #173; placing the builder in `gibbering_tales_web` respects the current dependency order.

**Role-gating:** `build(state, viewer_role)` returns different `action_bar` content per role. DM receives an empty action bar from the builder; player receives the ruleset's `action_buttons/2` output. DM-specific tools (session controls, initiatives, interventions) remain in the DM controls panel, driven directly by socket assigns, not the HUD.

**Boundary:**
- HUD covers: `action_bar`, `overlays` (move tiles + attack targets), `prompts` (empty for now — roll prompt stays event-driven in socket), `status_strip` (entity conditions)
- Ephemeral UI state stays in socket assigns: `panel_subject`, `dm_panel`, `dm_intervene_entity_id`, `roll_prompt`, `selected_spell`
- DM-only state (`hidden_entity_ids`, `initiative_values`, `pending_initiative_rolls`) moves from template locals to socket assigns — no longer read directly from `ruleset_state` in the template

**Derived implementation issue:** #173 (implements `GibberingTalesWeb.HUD.build/2` and refactors `GameLive` templates).

## Acceptance criteria

- [x] `%GibberingEngine.HUD{}` struct fields are specified and justified
- [x] Computation site decision (engine callback vs. Tales helper vs. LiveView) is made and documented
- [x] Role-gating approach (player vs DM HUD) is decided
- [x] Boundary between HUD data and ephemeral LiveView state is drawn
- [x] At least one implementation issue is derived (#173)
