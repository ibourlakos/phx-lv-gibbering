# #99 · Multi-style appearance system — style_id keying, per-style records, graceful fallback
**Status:** open
**Opened:** 2026-06-06
**Priority:** medium
**Tags:** architecture, rendering

Every displayable piece of game content must support multiple interchangeable art styles. A "style" is a named set: palette variables, SVG filter definitions, asset references, and typographic choices. Selecting a style at the campaign or server level swaps the full set.

Core design requirements:
- All appearance records are keyed by `(content_id, style_id)` — not a single canonical look per content item
- A content item without an appearance for the active style falls back gracefully (placeholder silhouette, not a broken render)
- New styles ship as data, not code — the rendering pipeline resolves which appearance to use based on active style
- Style definition includes: palette variable set, SVG filter defs, and a short descriptor

Schema changes:
- `styles` table: id, name, description, palette (JSONB), filter_defs (text or JSONB)
- `appearances` table refactored to include `style_id` FK (currently has `entity_id` only — check existing schema)
- `content_type` column on appearances to cover non-entity content (tiles, decorations, UI icons)

Depends on #98 (DST art direction spec) to define what the first concrete style must contain.

**Acceptance criteria**
- [ ] `styles` table exists with the default DST style seeded
- [ ] `appearances` table keyed by `(content_id, content_type, style_id)`
- [ ] Fallback rendering path: if no appearance exists for active style, a placeholder silhouette is shown (no crash, no blank)
- [ ] Rendering pipeline reads active style from campaign or server config and resolves appearances accordingly
- [ ] Style switch (test via seed data) updates rendered entities without requiring a schema change
- [ ] Existing rendering code updated to use style-resolved appearances; no hardcoded DST palette references remain
