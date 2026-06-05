# #50 · Character schema and context
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-05
**Priority:** high
**Tags:** architecture, gameplay

Create the `characters` DB table, Ecto schema (`Gibbering.Character`), and context (`Gibbering.Characters`) with full CRUD and ownership enforcement.

A `Character` is a player-owned, campaign-agnostic template. It holds the complete D&D 5e character sheet plus appearance, life events, and starting items. It is never mutated by campaign activity — campaign-specific state lives on `CampaignCharacter` (see #54).

**Schema fields**
- Identity: `name`, `race`, `class` (array — single entry at creation, multi-class via level-up), `level` (default 1), `alignment`, `background_key`
- Ability scores: `strength`, `dexterity`, `constitution`, `intelligence`, `wisdom`, `charisma`
- Proficiencies: `skill_proficiencies` (array), `tool_proficiencies` (array), `languages` (array)
- Spells: `spells_known` (array of spell keys)
- Personality: `personality_traits`, `ideals`, `bonds`, `flaws` (strings)
- `appearance` (JSONB): `body_type`, `head`, `hair_style`, `hair_color`, `skin_tone`, `eye_color`
- `life_events` (JSONB array): `era`, `type`, `title`, `description`, `mechanical_note`
- `starting_items` (JSONB array): `key`, `name`, `source`, `quantity`
- `user_id` FK → users (owner)

**Acceptance criteria**
- [ ] Migration creates the `characters` table with all fields above
- [ ] `Gibbering.Character` Ecto schema with changesets and validations
- [ ] `Gibbering.Characters` context: `list_for_user/1`, `get/2` (ownership-checked), `create/2`, `update/3`, `delete/2`
- [ ] Ownership enforced — a user cannot read, edit, or delete another user's character
- [ ] `mix precommit` passes
