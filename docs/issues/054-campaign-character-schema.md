# #54 · CampaignCharacter schema
**Status:** closed
**Closed:** 2026-06-06
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** architecture, gameplay

Add a `campaign_characters` table and `Gibbering.CampaignCharacter` Ecto schema. This is the DM-adjusted instance of a `Character` template within a specific campaign. It is separate from `campaign_members` (which is access control only).

A player may have more than one `CampaignCharacter` in a campaign (ensemble play, character replacement). The DM controls which are active.

**Ownership vs control**
- `owner_id` — user who owns the character template
- `controller_id` — user currently playing this character (defaults to owner; DM can reassign)
- `active` — boolean; DM controls which characters are in play at any given time

**Override fields** (all nullable — `nil` means "use template value")
- `override_level`, `override_ability_scores` (JSONB), `override_background_key`, `override_starting_items` (JSONB), `override_bonus_proficiencies` (array)

**Campaign-scoped additions**
- `dm_life_events` (JSONB array) — DM-added events, merged with template events at hydration
- `campaign_relations` (JSONB array) — bidirectional relations scoped to this campaign

**Acceptance criteria**
- [ ] Migration creates `campaign_characters` with all fields above
- [ ] `Gibbering.CampaignCharacter` Ecto schema with changesets
- [ ] `Gibbering.CampaignCharacters` context: `list_for_campaign/1`, `get/2`, `create/2`, `update/3`
- [ ] DM can set `active`, `controller_id`, and all override fields
- [ ] A non-owner controller can read (but not edit) the resolved character sheet
- [ ] `mix precommit` passes
