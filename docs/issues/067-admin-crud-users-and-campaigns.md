# #67 · Admin CRUD — Users and Campaigns

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-07
**Priority:** medium
**Tags:** architecture, gameplay

Core support tooling for the two most operational entities: player accounts and active campaigns.

Depends on [#64](064-admin-router-scope-and-pipeline.md) and [#65](065-support-users-schema-and-auth.md). All mutating actions must call `AuditLog.log_action/4` (see [#66](066-support-audit-log.md)).

**Users**
- [x] `/admin/users` — list with username search
- [x] `/admin/users/:id` — inspect: account details, campaign memberships, suspension status
- [x] Suspend/unsuspend action (sets a `suspended_at` timestamp on `users`); suspended users cannot log in to the game app
- [ ] Manual email verification action — deferred: users schema has no email field (out of scope)

**Campaigns**
- [x] `/admin/campaigns` — list all campaigns (active and inactive) with DM and status
- [x] `/admin/campaigns/:id` — inspect: metadata, participant list, creation date
- [x] Force-close action — gracefully terminates the campaign GenServer via `DynamicSupervisor.terminate_child/2`; logged in audit log with reason
