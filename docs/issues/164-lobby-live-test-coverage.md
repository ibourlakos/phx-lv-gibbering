# #164 · LobbyLive test coverage

**Status:** closed
**Opened:** 2026-06-29
**Closed:** 2026-06-30
**Priority:** medium
**Tags:** ops, ui

`LobbyLive` has no test file. The lobby is the entry point for every campaign session — character assignment, player readiness, and session start gating all live here. This is a coverage gap identified in the test suite audit.

**Acceptance criteria**
- [x] `test/gibbering_web/live/lobby_live_test.exs` exists with ≥ 10 tests (17 tests)
- [x] Covers: DM mounts lobby, player mounts lobby, character joined event reflected, character left event reflected
- [ ] Covers: DM cannot start session with zero characters assigned, DM can start when ≥ 1 character assigned — deferred: no such gate exists in current LobbyLive; "Start Game" is a plain `<a>` link
- [ ] Covers: player cannot start session — same; no LiveView event, deferred
- [x] `mix precommit` passes (971 tests, 0 failures)

Also fixed three pre-existing bugs uncovered by the tests: `me.role` → `me.id == campaign.dm_id` in template DM check; fallback `entity_sprite` component crash when `entity` assign absent; race traits and class features accessed via atom keys on string-keyed maps.
