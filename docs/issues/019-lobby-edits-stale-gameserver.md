# #19 · Lobby character edits don't propagate to a running GameServer

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** medium
**Tags:** bug, architecture

## Problem

`GameServer.init/1` loads all entities from the DB once at startup and holds them in memory as a `State` struct. If a player edits their character in the lobby (name, race, class) *after* the `GameServer` for that campaign has already started, the DB is updated but the running GenServer still has the old data.

This means:
- A player changes their character name in the lobby → the game board still shows the old name.
- Race/class changes (HP, speed, stats) are invisible in-game until the server restarts.

In practice the GameServer starts on the first `/game/:id` request. If players set up in the lobby *before* anyone visits the game URL this is not a problem — but it is a race condition that will be hit in normal use.

## Options

**A. Reload on game start** — The GameServer always re-loads entity data from DB when it receives its first player connection (a "start of game" event). Simple; breaks the "persistent running server" model.

**B. Lobby sends a message** — `LobbyLive` calls `GameServer.reload_entities(game_id)` after saving a character. The GenServer re-fetches entities from DB. Requires a `handle_call(:reload_entities, ...)` callback.

**C. Lobby prevents edits once game is live** — If the GameServer is already running, the lobby goes read-only. Simplest guard; poor UX.

**Decision: Option B** — lobby sends a message. After each entity-mutating event (`save_slot`, `add_slot`, `remove_slot`), `LobbyLive` calls `SceneServer.reload_entities/1` if the server is running. The GenServer re-fetches all entities for the campaign from DB and merges them into the runtime state, preserving per-entity runtime fields (position, action economy, resources, conditions). Heroes removed from the DB are dropped from the state; new heroes are hydrated fresh.

**Acceptance criteria**
- [x] Decision recorded here
- [ ] Lobby character edits are always reflected in the game board with no manual server restart required
