# #145 · Player auto-roll preference

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-19
**Priority:** medium
**Tags:** architecture, gameplay, rules

## Context

Derived from brainstorm #28 (player dice roll prompt + auto-roll preference).

Currently all dice rolls are auto-generated server-side. Some players want to roll
physical dice and enter results; others prefer seamless auto-roll. The preference
should be stored per player per campaign so it persists across sessions.

## What needs to happen

1. Add `auto_roll: boolean, default: true` column to `campaign_characters` table via
   a migration.
2. Expose the field in `Gibbering.Campaigns.CampaignCharacter` schema.
3. Add a toggle control to the in-session player settings panel (or a gear/cog
   accessible from the game view). Label: "Auto-roll dice" (on = auto, off = prompt me).
4. Update the toggle via a `handle_event` in `GameLive` that calls a `Campaigns`
   context function to persist the change.
5. Include `auto_roll` in the `GameLive` socket assigns so the engine path can query
   it when dispatching rolls.

## Out of scope

- The actual roll prompt component and SceneServer pending-roll state (see #146).
- Per-roll-type granularity (one toggle covers all player rolls for now; see
  brainstorm #28 open question 1).

**Acceptance criteria**
- [x] Migration adds `auto_roll boolean not null default true` to `campaign_characters`
- [x] Schema and changeset updated
- [x] Toggle visible in-session for the active player (not DM, not spectators)
- [x] Toggle persists across page reload
- [x] `auto_roll` value available in `GameLive` socket assigns for the current player's character
- [x] `mix precommit` passes

**Implementation notes:**
- `CampaignCharacters.get_active_for_player/2` queries by `owner_id + active == true`.
- Toggle renders only when `not @is_dm and not is_nil(@campaign_character)`.
- `CampaignCharacters.set_auto_roll/2` uses a dedicated `auto_roll_changeset` on the schema.
- `@auto_roll` and `@campaign_character` added to `GameLive` socket assigns at mount.
