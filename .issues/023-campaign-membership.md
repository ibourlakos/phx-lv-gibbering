# #23 · Campaign membership and DM assignment

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-05
**Priority:** high
**Tags:** architecture, gameplay

## Problem

There is no formal link between users and campaigns. Any authenticated user can open any lobby or game URL. The DM has no ownership of a campaign in the DB — only a runtime role check in the lobby.

Brainstorming doc `05-initial-data-entities.md` identifies `campaign_members` and `dm_id` as core schema pieces.

## Proposed approach

1. Add `dm_id` (FK → users) to `campaigns` table.
2. Create `campaign_members` join table: `campaign_id`, `user_id`.
3. Add `Gibbering.Campaigns` context with `join_campaign/2`, `member?/2`, `list_campaigns_for_user/1`.
4. Update seeds: create seed DM user, associate with campaign.
5. Gate `/lobby/:id` and `/game/:id`: redirect non-members to home with flash.

## Known limitations / future work

- No invite flow — members added by DM or by direct join (future).
- No spectator role in campaign_members (future).

**Acceptance criteria**
- [x] `campaigns.dm_id` FK present in migration
- [x] `campaign_members` table with unique index on `(campaign_id, user_id)`
- [x] `Gibbering.Campaigns` context: `join_campaign/2`, `member?/2`, `list_campaigns_for_user/1`
- [x] Seeds wire up a DM user and `campaign_members` row
- [x] Lobby redirects non-members to `/` with error flash
- [x] Home page shows all campaigns with Join/Play depending on membership
