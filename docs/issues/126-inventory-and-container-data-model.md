# #126 · Inventory and container data model

**Status:** open
**Opened:** 2026-06-12
**Priority:** low
**Tags:** architecture, gameplay

Implement the data model decisions from discovery issue #80.

Adds the `stats["object_subtype"]` field to world object entities, the `stats["items"]` field to loot containers, and the `stats["inventory"]` field to creatures. Updates seed data with at least one loot container. Updates the data model doc.

Depends on: #79 (`Data.Items` module, closed), #46 (equipped item JSONB, closed).

**Acceptance criteria**
- [ ] `Gibbering.Entity` schema and `Data.Entities` seed support `stats["object_subtype"]` = `"loot_source" | "static_decor"` for `type: "object"` entities
- [ ] `stats["items"]` on a loot-source entity holds `[%{"instance_id" => uuid_string, "item_key" => string, "quantity" => integer}]`; empty list `[]` for an empty container
- [ ] `stats["inventory"]` on creature entities (`"hero"`, `"monster"`) holds the same shape; empty list `[]` initially
- [ ] Tags `"interactable"` and `"passable"` are documented as the canonical tag names for world objects in the data model doc
- [ ] At least one `LootSource` world object seeded in the test/dev campaign with a small item set (e.g. 20 arrows, 1 shortsword)
- [ ] Data model doc (`docs/architecture/data-model.md`) updated: `entities.stats` known-keys table, runtime entity map shape, WorldObject section
- [ ] `mix precommit` passes
