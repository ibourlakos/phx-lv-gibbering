# #11 · Supervision tree design for GameServer processes

**Status:** open
**Opened:** 2026-06-04
**Priority:** high
**Tags:** architecture

No brainstorm addresses how `GameServer` GenServer processes are named, registered, or supervised. The missing design decisions are:

- **Process registry:** how does a LiveView find its `GameServer` by `game_id`? Options: `Registry` with a `{GameServer, game_id}` key, `:via` tuple, or a global name. `Registry` is the idiomatic OTP choice and scales across the node.
- **Supervisor strategy:** `DynamicSupervisor` is required since game sessions are created at runtime. A static `Supervisor` with `:simple_one_for_one` is the older equivalent.
- **Crash semantics:** what does a connected LiveView do when its backing `GameServer` crashes and restarts? The socket goes dead unless LiveView has a reconnect path back to a recovered or freshly started process.
- **Shutdown:** when the last player disconnects, should the `GameServer` terminate immediately, persist state and terminate, or linger for a reconnect window?

This must be designed before #12 (persistence) and #3 (save/load order) can be resolved.

**Acceptance criteria**
- [ ] `GameServer` processes are started under a `DynamicSupervisor`
- [ ] Process lookup uses `Registry` keyed by `game_id`
- [ ] LiveView reconnect after a `GameServer` crash either resumes the game or surfaces a clear error
- [ ] Shutdown policy (immediate vs. linger) is decided and documented here
- [ ] Decision reflected in `docs/architecture.md`
