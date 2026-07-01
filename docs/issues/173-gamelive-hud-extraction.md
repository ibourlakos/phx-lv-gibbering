# #173 · GameLive HUD extraction — render from `%HUD{}` instead of raw Engine.State

**Status:** open
**Opened:** 2026-07-01
**Priority:** medium
**Tags:** architecture, ui, rendering

Refactor `GameLive` to render HUD elements (action bar, overlays, prompts, status strip) from a `%GibberingEngine.HUD{}` struct rather than reading raw `Engine.State` and `ruleset_state` directly. Implement the Tales HUD helper that populates the struct for the DnD5e ruleset.

Gated on #172 (HUD struct design) and WP-S completing.

---

## Scope

### `GibberingTales.HUD` module (new, in `gibbering_tales`)

- `build(state, viewer_role)` — reads `Engine.State` + `DnD5e.RulesetState`, returns `%GibberingEngine.HUD{}`
- Populates:
  - `action_bar` from available actions given current turn/phase/entity
  - `overlays` from `state.valid_moves`, `state.valid_targets`
  - `prompts` from `ruleset_state.awaiting_roll`, `ruleset_state.pending_roll`
  - `status_strip` from entity conditions (D&D condition → status icon; replaces ConditionBadge web rendering)
- Role-gated: DM gets intervention actions + initiative panel; player gets character actions only

### `GibberingTalesWeb.GameLive` refactor

- After each `game_state` assign update, call `GibberingTales.HUD.build/2` and assign `hud`
- Replace direct `game_state.valid_moves`, `game_state.entities[actor_id]` reads in templates with `hud.*` fields
- Action bar template renders `@hud.action_bar` list — no D&D action names hardcoded in templates
- Dice prompt renders `@hud.prompts` — no `ruleset_state.awaiting_roll` in template
- Valid-move overlay renders `@hud.overlays` — no `game_state.valid_moves` in template
- Ephemeral UI state (`panel_subject`, `dm_panel`, `dm_intervene_entity_id`) stays in socket assigns — not part of HUD

### DnD5e layer

- `Rulesets.DnD5e.RulesetState` may need minor field additions to support HUD computation (e.g. surfacing which actions the active entity has already used)

## Out of scope

- HUD for the admin campaign monitoring view — that reads engine state via a separate read path
- Redesigning the panel layout (#22, #18) — HUD extraction is plumbing; layout is a separate concern
- `GibberingDuels` HUD — Phase 3 proof-of-concept; DnD5e is the reference implementation

## Acceptance criteria

- [ ] `GibberingTales.HUD.build/2` exists and is covered by unit tests
- [ ] `GameLive` templates contain no direct reads of `ruleset_state` fields
- [ ] `GameLive` templates contain no hardcoded D&D action names or condition strings
- [ ] `@hud.action_bar`, `@hud.overlays`, `@hud.prompts`, `@hud.status_strip` drive the four main HUD areas
- [ ] DM and player roles produce different `action_bar` content from the same `build/2` call
- [ ] All existing GameLive LiveView tests pass
- [ ] `mix precommit` passes
