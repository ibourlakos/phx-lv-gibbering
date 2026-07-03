# #177 · Test-compile warnings: unused default args in chest fixtures
**Status:** open
**Opened:** 2026-07-03
**Priority:** low
**Tags:** ops

`mix test` emits two "default values for the optional arguments … are never used"
warnings:

- `apps/gibbering_tales_web/test/engine/scene_server_test.exs:629` — `insert_chest/2`
- `apps/gibbering_tales_web/test/gibbering_tales_web/live/game_live_test.exs:661` — `insert_adjacent_chest/2`

Note: these slip through the precommit gate because `mix precommit` runs
`compile --warnings-as-errors` (lib code only) before `test`; test files compile during
`mix test` without warnings-as-errors. Consider adding
`test: ["compile --warnings-as-errors", …]`-style enforcement or
`ExUnit.start(…)`-side config if we want the gate to cover test code too.

**Acceptance criteria**
- [ ] Both warnings fixed (drop the unused defaults or use them)
- [ ] Decision recorded (in this issue) on whether test-code warnings should fail precommit
- [ ] `mix precommit` passes
