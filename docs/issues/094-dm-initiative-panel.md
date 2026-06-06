# #94 · DM turn and initiative management panel
**Status:** open
**Opened:** 2026-06-06
**Priority:** medium
**Tags:** ui, gameplay

The DM needs UI controls to manage initiative order and turn flow during combat, bypassing the normal player-driven flow.

Required controls:
- View and reorder the initiative list (drag or up/down buttons)
- Add an entry (e.g., a monster that joins mid-combat) or remove one (creature killed or leaves)
- Skip a player's turn (e.g., AFK) or force-end a player's turn
- Roll initiative on behalf of a player or NPC
- Advance to the next turn manually (DM-driven override of the normal advance trigger)

**Acceptance criteria**
- [ ] DM panel shows the full initiative list with current turn highlighted
- [ ] DM can reorder entries; order change broadcasts to all connected clients
- [ ] DM can add / remove initiative entries; list updates live for all clients
- [ ] "Skip turn" and "Force end turn" buttons work and advance state correctly
- [ ] "Roll initiative" button available on each entry; result is applied to that entry's initiative value
- [ ] All DM actions go through the same GameServer event pipeline as player actions (no separate code path)
