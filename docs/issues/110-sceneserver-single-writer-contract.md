# #110 · SceneServer single-writer contract

**Status:** closed
**Closed:** 2026-06-07
**Opened:** 2026-06-07
**Priority:** medium
**Tags:** architecture

The polytope treatise (§5.4) resolves the concurrent event ordering problem for this system: SceneServer (currently `Gibbering.Engine.GameServer`) is the single logical writer to the scene event stream. All commands flow through it; it produces all events from each command in a single atomic batch. Total ordering is trivially maintained because there is exactly one writer.

This is both an architectural constraint that must be documented and enforced, and a prerequisite for any persistent event log or hash-chained event stream implementation. If any other process ever emits scene-level domain events directly to the bus, the single-writer guarantee breaks and total ordering is lost.

The boundary is:
- SceneServer emits scene events (game state changes, turn transitions, damage, conditions, movement)
- Web adapter (GameLive, LiveView) relays UI-level notifications but does not emit domain events
- No other context emits events on behalf of the Scene context

This issue is primarily documentation and enforcement, with a potential audit component (similar to #109).

**References**
- `docs/papers/polytope-architecture.md` §5.4 (single writer per chain — the natural architecture), §5.3 (hash-chained logs — requires single writer)
- Issue #109 (compound bus separation — establishes what counts as a "scene event")
- Issue #111 (cascade batch emission — defines what SceneServer emits)

**Acceptance criteria**
- [ ] The single-writer contract is documented in `docs/architecture.md` and/or as a module doc on SceneServer
- [ ] Any existing violation (another process broadcasting scene-level domain events) is identified and fixed or tracked
- [ ] The contract is stated as: SceneServer is the sole emitter of scene-scoped events; all commands targeting the scene route through SceneServer via the command bus (C)
- [ ] Tests verify that all scene domain events originate from SceneServer (or can be traced to it via causation)
