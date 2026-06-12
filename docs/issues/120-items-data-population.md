# #120 · Items data module population — ≥20 SRD-legal items with appearance records

**Status:** deferred
**Opened:** 2026-06-12
**Deferred because:** Items require an inventory system design (#80) before a standalone `items` table makes sense; seeding more entries into the existing JSONB-based `Data.Items` is low value without the supporting schema. Un-defer alongside or after #80.
**Priority:** low
**Tags:** gameplay, rules, architecture

The initial content population (#89) deferred item seeding because the items schema was undefined. Items currently live as JSONB in `entity.stats` (`equipped_weapon`, `equipped_armor`) backed by `Gibbering.Data.Items` — a simple data module that exists but has minimal entries.

This issue covers:
- Populate `Gibbering.Data.Items` with ≥20 SRD-legal items: common weapons (longsword, shortsword, dagger, handaxe, greataxe, quarterstaff, crossbow, shortbow), armor (leather, chain mail, plate), shields, and consumables (health potion, antitoxin)
- Add `"item"` appearance records to the `appearances` table for the default DST style: `content_type: "item"`, `content_key: "<item_key>"`, `data: %{"icon_key" => ..., "tint" => ...}`
- Legal provenance confirmed for every item (SRD 5.1 CC-BY-4.0)

**Depends on:** #80 (inventory and loot container system) for schema context — do not precede with a standalone `items` table design without that issue.

**References**
- `docs/game-content-taxonomy.md` — Item upsert checklist
- Issue #79 (closed) — existing `Data.Items` structure
- Issue #80 — inventory system (deferred); shape of a future `items` table
- Issue #89 (closed) — initial content population; items AC deferred here

**Acceptance criteria**
- [ ] ≥20 SRD-legal items present in `Gibbering.Data.Items`
- [ ] Each item has: `key`, `name`, `item_type`, `damage_dice` or `ac_bonus`, `weight`, `cost_gp`, `tags`
- [ ] `"item"` appearance records seeded for the default style for each new item
- [ ] `mix test` passes with no regressions
- [ ] Legal provenance confirmed (SRD 5.1 CC-BY-4.0) for all added content
