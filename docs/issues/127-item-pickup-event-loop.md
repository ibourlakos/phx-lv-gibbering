# #127 · Item pickup event loop

**Status:** closed
**Opened:** 2026-06-12
**Closed:** 2026-06-19
**Priority:** low
**Tags:** gameplay, architecture, ui

Implement the SceneServer event handlers and LiveView UI for the loot pickup loop.

The loop: acting creature opens an adjacent container → container item list surfaces in a panel → player selects items to take → items transfer from container into creature inventory → creature weight is recalculated and displayed.

Depends on: #126 (inventory data model).

**Acceptance criteria**
- [x] `SceneServer.handle_event(:open_container, %{container_id: id}, state)` — validates acting creature is adjacent (Chebyshev distance ≤ 1) to the container entity; returns `:error` if not adjacent or container has no `"loot_source"` sub-type
- [x] `SceneServer.handle_event(:take_item, %{container_id: id, instance_id: uuid, quantity: n}, state)` — moves `n` units of the specified item instance from container `stats["items"]` to acting creature `stats["inventory"]`; merges stackable items (same `item_key`, non-magical) by accumulating quantity; leaves unique/magical items as distinct instances; emits an `EventBatch` with a scene event
- [x] `SceneServer.handle_event(:equip_item, %{instance_id: uuid}, state)` — moves matching inventory item to `stats["equipped_weapon"]` or `stats["equipped_armor"]` (determined by item type from `Data.Items`); removes old equipped item back to inventory if slot was occupied; triggers `DnD5e.Stats` re-derivation of AC/attack bonus
- [x] Carry weight is computed as `Enum.sum(inventory, fn i -> Data.Items.get(i["item_key"]).weight_pounds * i["quantity"] end)` and stored in `stats["carry_weight"]` after any inventory mutation
- [x] LiveView panel: when container is opened, a side panel surfaces the container's item list with name, quantity, weight; "Take" button per item, "Take All" button for the container; closes on "Done" or when the container is emptied
- [x] LiveView updates (panel open/close, inventory list, carry weight display) are driven by the EventBatch projection, not direct State reads
- [x] `mix precommit` passes
