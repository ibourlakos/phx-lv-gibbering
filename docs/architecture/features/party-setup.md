# Party Setup Flow

```
/ (home)  →  /lobby/:id  →  /game/:id
```

The lobby (`GibberingTalesWeb.LobbyLive`) is a LiveView where players claim character slots before the game starts:

1. Each browser session gets a player identity (currently derived from the session CSRF token — see #18 for the known limitation).
2. A player clicks **Play as [name]** to claim a hero entity slot.
3. They can edit name, race, and class — the lobby recalculates HP, speed, and stat bonuses from `Catalogue.Race` and `Catalogue.Class` (and the legacy `Data.*` in-memory tables for now), then persists to the DB.
4. The DM clicks **Start Game** which navigates to `/game/:id`.

PubSub topic `"lobby:#{campaign_id}"` propagates claim/release events to all connected lobby sessions so multiple browser tabs stay in sync.

> **Known issue (#18):** player identity is tied to the browser session (CSRF token), so two tabs in the same browser share an identity. Proper per-player identity is required before same-browser multi-player works correctly.

> **Known issue (#20):** lobby character edits write to the DB, but a `SceneServer` already running for the same campaign holds a stale in-memory snapshot. The server must be restarted (or the lobby must force a reload) for changes to take effect.
