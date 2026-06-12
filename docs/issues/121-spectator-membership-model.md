# #121 · Campaign membership: spectator role and invite flow
**Status:** open
**Opened:** 2026-06-12
**Priority:** low
**Tags:** architecture, gameplay

Add `spectator` as a first-class campaign membership role and extend the invite mechanism so any campaign member can invite spectators.

Derived from #92 (spectator role discovery).

## Scope

- Add `:spectator` to the `membership_role` enum on the campaign membership table (migration required)
- Add `invited_by_user_id` FK to the membership record — tracks who sent the invite, used to scope the spectator list in Q4 display logic
- Extend the invite token mechanism (#91) to support spectator invites: any campaign member (player or DM) can generate a spectator invite link
- Player invites (which grant `membership_role: :player`) remain DM-only — enforce this at the authorization layer
- Spectator members have no character assignment (no FK to `campaign_characters` / `CampaignCharacter`)

## Notes

- Spectator → player promotion is handled by the DM sending a standard player invite to the spectator. The spectator disconnects and re-joins through the normal player join flow. No migration path in the data model is needed.

**Acceptance criteria**
- [ ] Migration adds `:spectator` to `membership_role` enum and `invited_by_user_id` FK
- [ ] Any authenticated campaign member can generate a spectator invite link
- [ ] Player invite generation remains restricted to DMs (authorization check)
- [ ] Spectator membership records have no character assignment; constraint enforced or documented
- [ ] `invited_by_user_id` populated on creation for both spectator and player invites
- [ ] Existing player/DM membership flows unaffected
- [ ] Integration tests cover: spectator invite by player, spectator invite by DM, player invite restricted to DM
