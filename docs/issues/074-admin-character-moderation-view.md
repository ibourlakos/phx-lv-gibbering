# #74 · Admin character moderation view

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** architecture, gameplay

Support moderators need a read-only view of player-owned character templates for moderation purposes — offensive names, inappropriate appearance data, or flagged content.

Depends on [#64](064-admin-router-scope-and-pipeline.md), [#65](065-support-users-schema-and-auth.md), and the `characters` table from [#50](050-character-schema-and-context.md).

**Acceptance criteria**
- [ ] `/admin/characters` — paginated list, searchable by owner username or character name
- [ ] `/admin/characters/:id` — read-only inspect: all character fields (identity, appearance, background, life events, starting items), owner details, campaign memberships
- [ ] No edit capability — moderation actions are limited to flagging (which triggers the owning player's content trust review) or account-level action via the user inspect view ([#67](067-admin-crud-users-and-campaigns.md))
- [ ] Access restricted to `moderator` and `admin` roles
