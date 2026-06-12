# 11 — Game Content Workflow

**Status:** settled

## Context

Raw exploration of what changes are required when upserting game content — what content types exist and what layers each type touches. Goal: a definitive checklist to follow when adding any new content item.

---

## Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Content type taxonomy | 14 canonical types enumerated in `docs/game-content-taxonomy.md` — races, classes, backgrounds, spells, active effects/conditions, feats/abilities, items, tile textures, map decorations, map objects (interactive), monsters, notable individuals, visual effects, appearance components |
| 2 | Upsert workflow | Per-type layer checklist (schema, data module, seed, appearance, UI surface, rendering, rules integration, tests) documented in `docs/game-content-taxonomy.md`; use it as the reference for every content addition |
| 3 | Multi-style appearance slot | `appearances (style_id FK, content_type text, content_key text, data JSONB)` — unique on `(style_id, content_type, content_key)`; resolved by #99 |
| 4 | Character portability | Portable templates via `characters` table; campaign-scoped linking via `CampaignCharacter` (#54, closed) |
| 5 | Items schema | No standalone `items` table for now — items stored as JSONB in `entity.stats`; `Gibbering.Data.Items` module exists (#79, closed); standalone items table deferred until inventory system is designed (#80) |
| 6 | Subclasses | Expressed as class `features` JSONB array until a subclass picker is needed; no separate `subclasses` table yet |
| 7 | Initial content | 9 SRD-legal races, 12 classes, 12 monsters seeded (#89, closed); items population deferred (#120) |
| 8 | BG3-exclusive content | SRD-legal content first; BG3-exclusive races/content gated on legal resolution (#16) |
| 9 | Content editing tools | Out of scope for this brainstorm; tracked in #85 (content creation tools) |

---

## Cross-References

- Brainstorm #14 (isometric scene view) — art direction spec (#98) and multi-style system (#99) define the appearance slot schema
- Brainstorm #12 (player/DM experience) — character creation UI surfaces the content seeded here
- Issue #16 — LPC sprite copyleft risk; legal gate for non-SRD content

---

## Issues

_Triaged 2026-06-06, settled 2026-06-12_

| # | Title | Status |
|---|---|---|
| [#88](../issues/088-game-content-type-taxonomy.md) | Game content type taxonomy and upsert workflow | closed |
| [#89](../issues/089-initial-game-content-population.md) | Initial content population — races, classes, starter monsters/items | closed (items seeding deferred → #120) |
| [#120](../issues/120-items-data-population.md) | Items data module population — ≥20 SRD-legal items with appearance records | deferred |
