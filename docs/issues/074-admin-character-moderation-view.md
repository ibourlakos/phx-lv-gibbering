# #74 · Admin character moderation view

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-07
**Priority:** low
**Tags:** architecture, gameplay

Support moderators need a read-only view of player-owned character templates for moderation purposes — offensive names, inappropriate appearance data, or flagged content.

Depends on [#64](064-admin-router-scope-and-pipeline.md), [#65](065-support-users-schema-and-auth.md), and the `characters` table from [#50](050-character-schema-and-context.md).

**Acceptance criteria**
- [x] `/admin/characters` — list, searchable by owner username or character name
- [x] `/admin/characters/:id` — read-only inspect: all character fields (identity, appearance, background, life events, starting items), owner details, campaign memberships
- [x] No edit capability — owner links back to `/admin/users/:id` for account-level action
- [x] Access restricted to `moderator` and `admin` roles (controller plug redirects others to `/admin`)
