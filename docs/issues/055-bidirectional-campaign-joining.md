# #55 · Bidirectional campaign joining
**Status:** closed
**Closed:** 2026-06-06
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** architecture, gameplay

Support two flows for bringing a character into a campaign:

**Flow A — Player-initiated request**
A player selects one of their characters and requests to join a campaign. The DM sees a pending request and approves or rejects it. On approval a `CampaignCharacter` record is created and a `campaign_members` entry is upserted.

**Flow B — DM-initiated invite**
The DM invites a player (by username or user lookup) to a campaign. The player receives the invite, accepts, and selects which character from their roster to bring. On acceptance the same records are created.

Both flows result in the same end state: a `CampaignCharacter` record linking the character to the campaign, with the player as both owner and initial controller.

A campaign member without any `CampaignCharacter` records is a **spectator** — valid, no special handling needed.

**Acceptance criteria**
- [ ] Player can submit a join request for a campaign (selects character from roster)
- [ ] DM sees pending requests and can approve or reject
- [ ] DM can invite a player by username
- [ ] Player sees pending invites and can accept (selecting a character) or decline
- [ ] Approval/acceptance creates `CampaignCharacter` + upserts `campaign_members`
- [ ] Rejection/decline removes the pending record cleanly
- [ ] `mix precommit` passes
