# #72 · Drop `users.role` column

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-05
**Priority:** high
**Tags:** architecture

The `users.role` column (`"player" | "dm" | "support"`) is obsolete:
- `"support"` is superseded by the separate `support_users` table ([#65](065-support-users-schema-and-auth.md))
- `"dm"` is a per-campaign role (`campaigns.dm_id`), not a user attribute — the column implies a global DM role that does not exist in the data model

The column should be dropped before `support_users` auth ([#65](065-support-users-schema-and-auth.md)) ships, to avoid two competing auth models existing simultaneously.

**Acceptance criteria**
- [x] Migration drops `users.role` column
- [x] `Gibbering.Accounts.User` schema updated — `role` field removed
- [x] Any code that reads or pattern-matches on `user.role` is updated or removed
- [x] `docs/data-model.md` updated to remove the `role` column from the `users` table documentation
- [x] Tests pass; no references to `user.role` remain
