# #90 · Player campaign overview page
**Status:** open
**Opened:** 2026-06-06
**Priority:** medium
**Tags:** ui, gameplay

A logged-in player needs a home screen that surfaces their active campaigns and the characters they have in each one.

Minimum scope:
- List of campaigns the player is a member of, with campaign name, DM name, and current status (lobby / active / ended)
- Per campaign: the character(s) the player has in that campaign (name, class, level, avatar thumbnail)
- Entry points: join a new campaign (redirects to invite flow), enter lobby for an active campaign, view/edit character sheet

**Acceptance criteria**
- [ ] `/campaigns` or `/dashboard` route renders the player's campaign list
- [ ] Each campaign card shows: name, DM, status, character(s) belonging to this player
- [ ] Empty state handled: prompt to join or wait for an invite
- [ ] Links to lobby, character sheet, and join flow are correct and guarded by auth
- [ ] DM users see their owned campaigns with a "manage" link instead of a character card
