# #56 · Character template → live entity merge logic
**Status:** closed
**Closed:** 2026-06-06
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** architecture, rules

At scene hydration, merge a `Character` template with its `CampaignCharacter` overrides to produce the live entity map that the engine operates on. Override fields win; a `nil` override means "use the template value".

This merge happens in (the planned) `State.from_campaign/1` when loading a scene. The result is the entity record the engine and LiveView consume — the original `Character` and `CampaignCharacter` records are not touched during play.

**Merge rules**
- `level`: `override_level ?? character.level`
- `ability scores`: `override_ability_scores ?? character.{str,dex,...}` + race bonuses applied here
- `background`: `override_background_key ?? character.background_key` → proficiencies resolved from catalogue
- `starting_items`: `override_starting_items ?? character.starting_items` → equipped items derived
- `bonus_proficiencies`: appended to class + background proficiencies
- `life_events`: template events + `dm_life_events` merged (DM events appended)
- `controller_id`: becomes the `claimed_by` equivalent for the session

**Acceptance criteria**
- [ ] `Gibbering.Characters.merge/2` (or equivalent) produces a resolved entity map from `%Character{}` + `%CampaignCharacter{}`
- [ ] Race bonuses applied to ability scores during merge (not stored on template)
- [ ] All override fields follow the nil-fallback rule
- [ ] Proficiencies from class + background + bonus correctly merged and deduplicated
- [ ] Unit tests cover: all-nil overrides (pure template), full overrides (all DM values win), partial overrides
- [ ] `mix precommit` passes
