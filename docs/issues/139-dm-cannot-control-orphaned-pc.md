# #139 · DM cannot control orphaned PC — no action bar shown

**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** gameplay, ui, bug

When the DM advances the turn to a PC that has no player assigned
(an "orphaned" PC), the action bar does not appear. The DM has no way
to take actions on behalf of that character, stalling the session.

This affects any session where a player disconnects or is absent and
the DM needs to puppet their character through their turn.

**Acceptance criteria**
- [ ] When `active_hero_id` resolves to a PC and the viewer is the DM,
      the action bar (End Turn + available action buttons) renders as
      if the DM were that player
- [ ] The action bar correctly reflects the PC's available actions,
      spell slots, and movement for that turn
- [ ] DM acting on behalf of a PC produces the same engine events as
      a player acting directly
- [ ] `mix precommit` exits 0
