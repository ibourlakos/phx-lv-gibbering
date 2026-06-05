# #70 · UGC content schema, `content_trust` flag, and moderation queue

**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** Blocked on brainstorm #10 (content creation tools). The UGC schema must be designed alongside the player-facing content editor — neither can be meaningfully spec'd in isolation.
**Priority:** low
**Tags:** architecture, gameplay

Implement the user-generated content data layer and the admin moderation queue.

**Scope**
- `user_content` table: `id`, `owner_id` (FK → `users`), `content_type` (string), `visibility` (enum: `private` | `campaign` | `public`), `status` (enum: `draft` | `published` | `under_review` | `rejected`), `data` (JSONB), `rejection_reason`, `inserted_at`, `updated_at`
- `content_trust` boolean on `users` (migration)
- Submission logic: trusted players → `:published` directly; untrusted → `:under_review`
- Admin moderation queue LiveView: list of `:under_review` submissions with approve/reject actions
- Rejected submissions receive a `rejection_reason` shown back to the player
- Campaign eligibility enforced: only `:published` content can be selected in campaign setup

**Acceptance criteria**
- [ ] Brainstorm #10 settled and content type schemas defined
- [ ] `user_content` migration and Ecto schema
- [ ] `content_trust` column added to `users`
- [ ] Submission context function respects trust level
- [ ] Admin moderation queue LiveView with approve/reject, reason field on reject
- [ ] Campaign setup rejects non-`:published` content at the context layer
