# #66 · Support audit log

**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** architecture, ops

All actions taken by support users must be logged. The audit log is append-only, never deleted, and readable by all support roles.

**Acceptance criteria**
- [ ] Migration creates `support_audit_logs` table: `id`, `actor_id` (FK → `support_users`), `action` (string, e.g. `"user.suspend"`), `target_type` (string), `target_id` (string), `metadata` (JSONB), `inserted_at`
- [ ] `Gibbering.Admin.AuditLog` Ecto schema defined
- [ ] `Gibbering.Admin.log_action/4` — inserts a log entry; called by all support context functions that mutate state
- [ ] Audit log index LiveView in the admin panel — paginated, filterable by actor and action type
- [ ] No delete or update operations on `support_audit_logs` — entries are immutable
