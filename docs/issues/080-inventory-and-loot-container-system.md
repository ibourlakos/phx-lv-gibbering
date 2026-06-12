# #80 · Inventory and loot container system

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-12
**Priority:** low
**Tags:** discovery, architecture, gameplay

Design the item ownership model, container/loot entities on the grid, and the item-pickup gameplay loop.

The D&D 5e item world operates in two contexts:

**Possession (inventory):** A creature holds a list of item instances. Equipped items inject their properties into the creature's runtime stat calculation. Unequipped items sit in the inventory without mechanical effect.

**Spatial (environment):** Items that exist on the map live inside a `WorldObject` entity — a grid-positioned object with `is_passable` and `is_interactable` flags. The loot-source variant (`LootSource`) is a `Container` that a player can open and ransack. Static decor (`StaticDecor`) is purely visual with no inventory.

The pickup loop:
1. Engine checks the acting creature's tile is adjacent to the `WorldObject`.
2. Engine reads the container's item list and surfaces it to the player.
3. On "Take," engine moves item instances from the container into the creature's inventory.
4. Engine recalculates creature weight and equipped-item derived stats.

Open questions to settle before implementation:
- Does `WorldObject` become an entity variant in `SceneServer` state, or a separate spatial layer?
- How is item quantity tracked (stackable vs unique instances)?
- Does carry-weight impose a mechanical penalty, or is it purely informational in this engine?
- How does equipped-item stat injection interact with the `RuleModifier` pipeline (#31, #40)?

## Decisions (2026-06-12)

**WorldObject — entity variant.** `type: "object"` already exists in the `entities` table and runtime map. A new spatial layer would duplicate positioning, rendering, and hydration infrastructure for no gain. Sub-type lives in `stats["object_subtype"]` = `"loot_source" | "static_decor"`. The `is_passable`/`is_interactable` flags live in `tags` following the existing `["blocking"]`, `["destructible"]` tag pattern.

**Item quantity — uniform instance list.** `stats["inventory"]` (creature) and `stats["items"]` (container) both hold `[%{"instance_id" => uuid, "item_key" => string, "quantity" => integer}]`. Stackable items (arrows, potions of identical type, gold) merge on pickup — quantities accumulate under the existing stack's `instance_id`. Unique items (`is_magical: true` or a catalogue `is_unique` flag) never merge; each keeps its own `instance_id`.

**Carry-weight — informational only.** Track and display `total_weight` in the UI. No encumbered/heavily-encumbered conditions at this stage. The correct future hook is a `%RuleModifier{trigger: :passive, predicate: {:encumbered}, effect: {:reduce_speed, 10}}` once the inventory system is stable — deferred to a future issue.

**Equipped-item stat injection — new `:equipped_items` source in `collect_modifiers/3`.** The pipeline currently collects from `[:race_traits, :class_features, :active_conditions]`; `:equipped_items` becomes a fourth source. It reads `stats["equipped_weapon"]` and `stats["equipped_armor"]`, looks each key up in `Data.Items`, and returns that item's `modifiers: [%RuleModifier{}]` list. This requires adding a `modifiers` field to `Data.Items` entries (currently missing — the module has mechanical data but no RuleModifier translation). `DnD5e.Stats.armor_class/1` direct-read of `stats["equipped_armor"]` coexists as a transitional shortcut until the pipeline path is proven.

## Implementation issues

- #126 — Inventory and container data model (entity sub-type schema, `stats["inventory"]`/`stats["items"]` shape, seed data)
- #127 — Item pickup event loop (adjacency check, container surface, item transfer, weight display)
- #128 — Equipped item `collect_modifiers` integration (`Data.Items` `modifiers` field, `:equipped_items` pipeline source)

**Acceptance criteria**
- [x] All open questions above have a documented decision
- [x] Data model for creature inventory and `WorldObject`/`LootSource` grid entities is defined
- [x] Acceptance criteria for the implementation issue(s) derived from this discovery are written
