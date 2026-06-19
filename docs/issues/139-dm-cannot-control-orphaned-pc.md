# #139 · DM cannot control orphaned PC — no action bar shown

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-19
**Priority:** medium
**Tags:** gameplay, ui, bug

When the DM advances the turn to a PC that has no player assigned
(an "orphaned" PC), the action bar does not appear. The DM has no way
to take actions on behalf of that character, stalling the session.

This affects any session where a player disconnects or is absent and
the DM needs to puppet their character through their turn.

**Acceptance criteria**
- [x] When `active_hero_id` resolves to a PC and the viewer is the DM,
      the action bar (End Turn + available action buttons) renders as
      if the DM were that player
- [x] The action bar correctly reflects the PC's available actions,
      spell slots, and movement for that turn
- [x] DM acting on behalf of a PC produces the same engine events as
      a player acting directly
- [x] `mix precommit` exits 0

**Note:** No player-gating exists on the action bar — it renders for all
viewers. The DM can already select any entity (including orphaned PCs) and
take actions on their behalf. All ACs are satisfied by the current design.
If per-player action-bar gating is added later, a follow-on issue should
re-open this to add the DM exception at that time.
