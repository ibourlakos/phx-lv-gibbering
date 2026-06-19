# #151 · Campaign / Scene Phase 2 — scene_templates and campaign_scenes schema
**Status:** deferred
**Opened:** 2026-06-19
**Deferred because:** Depends on #85 (content creation tools brainstorm). Phase 2 schema design cannot proceed until the DM authoring surface is scoped; the tables must fit the editor model.
**Blocked by:** #85
**Priority:** medium
**Tags:** architecture, gameplay

Introduce the persistent scene layer decided in BS-17 (Q2, Q9):

- `scene_templates` table: `id`, `map_id` FK, `placements` JSONB (entity and item placements), `starting_conditions` JSONB (initial active effects), `owner_user_id`, `visibility`
- `campaign_scenes` table: `id`, `campaign_id` FK, `scene_template_id` FK, `sequence_order`, `overrides` JSONB (campaign-specific entity override set)
- Entity placement and scene-scoped entities moved from campaign-global to per-scene
- `starting_conditions` JSONB seeds the `active_effects` list in `Engine.State` at scene load

**Acceptance criteria**
- [ ] `scene_templates` migration and schema
- [ ] `campaign_scenes` migration and schema
- [ ] `SceneServer` loads entities and starting_conditions from scene template on map switch
- [ ] DM can select a scene template when starting a session (lobby UI)
- [ ] Seeds updated with at least one scene template per dev map
