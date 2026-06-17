# #126 · Inventory and container data model

**Status:** closed
**Opened:** 2026-06-12
**Closed:** 2026-06-17
**Priority:** low
**Tags:** architecture, gameplay

Implement the data model decisions from discovery issue #80.

Adds the `stats["object_subtype"]` field to world object entities, the `stats["items"]` field to loot containers, and the `stats["inventory"]` field to creatures. Updates seed data with at least one loot container. Updates the data model doc.

Depends on: #79 (`Data.Items` module, closed), #46 (equipped item JSONB, closed).

**Acceptance criteria**
- [x] `stats["object_subtype"]` = `"loot_source" | "static_decor"` supported for `type: "object"` entities (freeform `stats` JSONB; no changeset validation, consistent with existing stats-key handling). "The Rock" seeded as `static_decor`.
- [x] `stats["items"]` on a loot-source entity holds `[%{"instance_id" => uuid_string, "item_key" => string, "quantity" => integer}]`; `[]` for an empty container. Shape + constructor in `Gibbering.Rulesets.DnD5e.Inventory.item_instance/2`.
- [x] `stats["inventory"]` on creature entities (`"hero"`, `"monster"`) holds the same shape; seeded as `[]` initially on all four creatures.
- [x] Tags `"interactable"` and `"passable"` documented as the canonical world-object tag names in the data model doc.
- [x] `LootSource` world object seeded: "Battered Chest" holds 1 shortsword + 2 healing potions (arrows have no `Data.Items` key, so a valid SRD item set was substituted for the example).
- [x] Data model doc updated: `entities.stats` known-keys table (added object_subtype/items/inventory/equipped_*), new "WorldObject & inventory model" section. Runtime entity map shape already covers `stats` keys via "same keys as DB stats JSONB".
- [x] `mix precommit` passes (771 tests, 0 failures).
