# #18 · Player session identity: persistent UUID per browser session

**Status:** closed
**Closed:** 2026-06-05
**Opened:** 2026-06-05
**Priority:** high
**Tags:** architecture, gameplay

## Problem

The lobby currently identifies players by the session CSRF token (`session["_csrf_token"]`). This is wrong for two reasons:

1. The CSRF token is a security token, not a player identity — it can be rotated by the framework and is semantically incorrect.
2. There is no mechanism to associate a player name or display identity with a session, so the lobby just shows "YOU" without any persistent label.

Now that multiplayer is cross-browser (each player on their own device/session), the lobby needs a proper per-session player UUID.

## Proposed approach

On first visit to any page, a random UUID is generated and stored in the session (a plug or LiveView `on_mount` hook). This UUID is stable for the lifetime of the session cookie and is the lobby's player identity.

```elixir
# In a plug or :on_mount hook
player_id = Map.get(session, "player_id") || UUID.uuid4()
# persist back to session
```

The lobby should also let the player set a **display name** (stored alongside the UUID in the session or in a lightweight `lobby_players` ETS table). The player's display name appears on their claimed card so others can see who holds which slot.

**Acceptance criteria**
- [ ] A plug or `on_mount` hook assigns a stable `player_id` UUID on first visit and stores it in the session
- [ ] `LobbyLive` reads `player_id` from the session (not from CSRF token)
- [ ] Each lobby card shows the display name of the claiming player, not just "YOU"
- [ ] Refreshing the page does not lose the player's slot claim
