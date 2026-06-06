# #76 · Accounts context integration tests
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** medium
**Tags:** architecture, ops

`Gibbering.Accounts` sits at 22% coverage. The three untested functions all require a real DB row:

- `authenticate_user/2` — fetches user by username, verifies password hash
- `get_user_by_id/1` — repo get with nil-guard
- `get_user_by_username/1` — repo get_by with nil-guard

These are `DataCase` integration tests; they exercise the Ecto query layer and Bcrypt verification so mocking would defeat the purpose.

**Acceptance criteria**
- [x] `authenticate_user/2` tested: correct credentials → `{:ok, user}`, wrong password → `{:error, :invalid_credentials}`, unknown username → `{:error, :invalid_credentials}`
- [x] `get_user_by_id/1` tested: existing id → user struct, unknown id → `nil`
- [x] `get_user_by_username/1` tested: existing username → user struct, unknown → `nil`
- [x] All tests use `DataCase, async: false` with DB-inserted fixtures
- [x] Coverage on `Gibbering.Accounts` reaches ≥ 90%
