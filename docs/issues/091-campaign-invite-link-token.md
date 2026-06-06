# #91 · Campaign invite link / shareable token mechanism
**Status:** open
**Opened:** 2026-06-06
**Priority:** medium
**Tags:** architecture, ui, gameplay

Players need a way to join a campaign without the DM manually adding them by username. A shareable invite token (link) is the primary mechanism.

Scope:
- DM can generate an invite link for a campaign (token stored in DB, expires after a configurable window or on first use / N uses)
- Visiting the link while logged in: prompts the player to confirm joining the campaign, creates the membership record
- Visiting the link while not logged in: redirect to auth, then return to the invite confirmation
- DM can revoke a link at any time
- Link UI lives in the campaign management screen (DM prep page or campaign settings)

Distinct from #55 (bidirectional joining) which handles the backend membership record and DM-initiated direct invite; this issue is specifically the token URL mechanism.

**Acceptance criteria**
- [ ] `campaign_invites` table (or equivalent) stores token, campaign_id, created_by, expires_at, uses_remaining
- [ ] `GET /invites/:token` route handles the invite flow (confirm → join or reject)
- [ ] Unauthenticated users are redirected to login and returned post-auth
- [ ] DM UI shows current active invite link with copy-to-clipboard and revoke button
- [ ] Expired or revoked tokens show a clear error rather than a 500
- [ ] Joining via token calls the same membership creation path as #55
