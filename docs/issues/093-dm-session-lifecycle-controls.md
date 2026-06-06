# #93 · DM session lifecycle controls (start, pause, resume, end)
**Status:** open
**Opened:** 2026-06-06
**Priority:** medium
**Tags:** ui, gameplay, architecture

The DM needs explicit controls to manage the lifecycle of a game session from inside the live game view.

Required controls:
- **Start session** — transitions the lobby to active game state; broadcasts to all connected players
- **Pause session** — freezes all player inputs; a "Session Paused" overlay shown to players; server continues accepting DM inputs
- **Resume session** — lifts the pause; restores player input
- **End session** — archives current game state, transitions back to lobby or campaign overview; players see an end-of-session screen

Design notes:
- Pause should block player action events at the GameServer level, not just hide UI
- End session should prompt the DM for confirmation before archiving
- Session state transitions should be idempotent (double-clicking "pause" is harmless)

**Acceptance criteria**
- [ ] DM panel has Start / Pause / Resume / End buttons, shown conditionally based on current session state
- [ ] Player inputs are rejected server-side while paused (not just hidden client-side)
- [ ] Pause and resume broadcast a PubSub event that all connected LiveViews handle to show/hide the pause overlay
- [ ] End session shows a confirmation dialog; on confirm, state is archived and all sockets receive a redirect
- [ ] Session state persists across DM page reload (a refreshed DM can resume from correct state)
