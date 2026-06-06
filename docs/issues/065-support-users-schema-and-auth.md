# #65 · `support_users` schema, migration, context, and auth

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** medium
**Tags:** architecture, ops

Create the `support_users` table and the authentication layer for support users. Fully decoupled from the player `users` table — linked only by `email` convention, not by schema join.

**Acceptance criteria**
- [x] Migration creates `support_users` table: `id`, `email`, `hashed_password`, `role` (enum: `viewer` | `moderator` | `editor` | `admin`), `inserted_at`, `updated_at`
- [x] `Gibbering.Admin.SupportUser` Ecto schema defined
- [x] `Gibbering.Admin` context with `get_support_user_by_email_and_password/2`, `create_support_user/1`, `change_support_user/2`
- [x] Support login LiveView at `/admin/login` — email + password form, sets `support_user_id` in session on success
- [x] Support logout route clears the session
- [x] `RequireSupportUser` plug (from [#64](064-admin-router-scope-and-pipeline.md)) reads from `support_users` via this context
- [x] A seed function creates a default `admin`-role support user in dev (credentials in `.env.example`)
