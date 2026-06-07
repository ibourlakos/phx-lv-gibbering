# #99 · Multi-style appearance system — style_id keying, per-style records, graceful fallback
**Status:** closed
**Closed:** 2026-06-07
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
- [x] `styles` table exists with the default DST style seeded
- [x] `appearances` table keyed by `(style_id, content_type, content_key)`
- [x] Fallback rendering path: unknown content keys return gray `#7f8c8d` (no crash, no blank)
- [x] `Catalogue.appearances_for_style/1` loads the full appearance map at mount; GameLive reads active style via `Catalogue.default_style_slug/0`
- [x] Style switch requires only a DB data change — no code change to the rendering pipeline
- [x] `tile_fill/1`, `tile_stroke/1`, `sprite_color/1` hardcoded helpers replaced by `tile_fill/2`, `tile_stroke/2`, `entity_body_color/2` backed by the appearances map

**Scope note:** Named entity sprite SVGs (warrior, wizard, etc.) retain hardcoded DST colours in their
shape markup — those colours are integral to the sprite geometry and will be parametrised as part of
#100 (SVG fragment store). This issue covers the plumbing layer (tables, context, tile colours,
entity primary body colour) that #100 builds on.
