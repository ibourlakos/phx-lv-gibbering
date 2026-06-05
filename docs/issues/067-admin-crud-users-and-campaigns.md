# #67 · Admin CRUD — Users and Campaigns

**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** architecture, gameplay

Core support tooling for the two most operational entities: player accounts and active campaigns.

Depends on [#64](064-admin-router-scope-and-pipeline.md) and [#65](065-support-users-schema-and-auth.md). All mutating actions must call `AuditLog.log_action/4` (see [#66](066-support-audit-log.md)).

**Users**
- [ ] `/admin/users` — paginated list with search by email/name
- [ ] `/admin/users/:id` — inspect: account details, campaign memberships, content submissions, suspension status
- [ ] Suspend/unsuspend action (sets a `suspended_at` timestamp on `users`); suspended users cannot log in to the game app
- [ ] Manual email verification action

**Campaigns**
- [ ] `/admin/campaigns` — list all campaigns (active and inactive) with participant count and status
- [ ] `/admin/campaigns/:id` — inspect: metadata, participant list, creation date
- [ ] Force-close action — gracefully terminates the campaign GenServer via `DynamicSupervisor.terminate_child/2`; logged in audit log with reason
