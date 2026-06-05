# #12 · Persistence strategy: game state → Postgres

**Status:** open
**Opened:** 2026-06-04
**Priority:** high
**Tags:** architecture

Mid-game state is fully in-memory. A server restart wipes all active sessions. No brainstorm defines how game state maps to Postgres rows, whether event sourcing or snapshot-based persistence is used, or how a LiveView reconnects to a recovered session.

Design questions to resolve:

- **Snapshot vs event sourcing:** snapshot serialises the full `GameState` struct to a JSONB column on each action; event sourcing appends action events and replays. Snapshot is simpler; event sourcing gives a full audit log and replay capability (valuable for debugging and turn replays).
- **Write frequency:** every action, every turn, or only on explicit save? D&D turns are slow — per-action writes are safe.
- **Schema shape:** a single `game_sessions` table with a `state` JSONB column is the simplest start. Separate `events` table for event sourcing.
- **Recovery path:** on `GameServer` start, check Postgres for existing state and restore it. Combine with #11 (supervision) so the supervisor restarts the process and it self-heals.

Blocking: #3 (save/load order decision) and #11 (supervision tree) both depend on this design.

**Acceptance criteria**
- [ ] Persistence strategy decided (snapshot vs event sourcing) and documented here
- [ ] Ecto schema(s) defined and migrated
- [ ] Mid-game state survives `docker compose restart app`
- [ ] `GameServer` restores state from Postgres on start if a record exists for that `game_id`
- [ ] Decision reflected in `docs/architecture.md`
