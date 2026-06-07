# #75 · Admin campaign member management

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-07
**Priority:** medium
**Tags:** architecture, gameplay

Moderators need to remove a specific user from a specific campaign without suspending their account or force-closing the campaign. Targeted moderation for disruptive players.

Depends on [#67](067-admin-crud-users-and-campaigns.md). All actions logged via audit log ([#66](066-support-audit-log.md)).

**Acceptance criteria**
- [x] Campaign inspect view (`/admin/campaigns/:id`) shows the full member list with per-member remove action
- [x] Remove action deletes the `campaign_members` row and broadcasts a PubSub event to the running `SceneServer` (if active) so the removed player is ejected from the live session
- [x] Removed player receives a clear in-app notification (or is redirected on next action)
- [x] DM (`campaigns.dm_id`) cannot be removed via this action — removing the DM requires force-closing the campaign
- [x] Action is logged in the audit log with `target_type: "campaign_member"`, `target_id: "<campaign_id>:<user_id>"`, and a required reason field
- [x] Access restricted to `moderator` and `admin` roles
