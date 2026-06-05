# #71 · Admin catalogue CRUD

**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** The admin catalogue editor shares component design with the player-facing content creation tools. Blocked on brainstorm #10 settling the shared editor component surface.
**Priority:** low
**Tags:** architecture, gameplay

Support editors need to create and update official catalogue entries (Races, Classes, Backgrounds, Spells, Items, Conditions) without a code deploy.

**Scope**
- CRUD LiveViews in the admin panel for each catalogue entity type
- Changes are effective immediately (no deploy required)
- All writes go through the audit log ([#66](066-support-audit-log.md))
- Catalogue entries reference stable string keys used in export/import serialization ([#59](059-character-export-import.md))
- Editor components (form fields, preview) are shared with the player-facing content creation shell — see brainstorm [#10](../docs/brainstorming/10-content-creation-tools.md)

**Acceptance criteria**
- [ ] Brainstorm #10 settled and shared editor components defined
- [ ] Admin CRUD LiveViews for: Races, Classes, Backgrounds, Spells, Items, Conditions
- [ ] All mutations logged via `AuditLog.log_action/4`
- [ ] String key uniqueness enforced at the DB and context layer
