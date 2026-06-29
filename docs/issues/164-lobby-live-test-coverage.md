# #164 · LobbyLive test coverage

**Status:** open
**Opened:** 2026-06-29
**Priority:** medium
**Tags:** ops, ui

`LobbyLive` has no test file. The lobby is the entry point for every campaign session — character assignment, player readiness, and session start gating all live here. This is a coverage gap identified in the test suite audit.

**Acceptance criteria**
- [ ] `test/gibbering_web/live/lobby_live_test.exs` exists with ≥ 10 tests
- [ ] Covers: DM mounts lobby, player mounts lobby, character joined event reflected, character left event reflected
- [ ] Covers: DM cannot start session with zero characters assigned, DM can start when ≥ 1 character assigned
- [ ] Covers: player cannot start session (start is DM-only gate)
- [ ] `mix precommit` passes
