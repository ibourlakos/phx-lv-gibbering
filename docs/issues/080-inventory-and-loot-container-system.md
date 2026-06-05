# #80 · Inventory and loot container system

**Status:** open
**Opened:** 2026-06-05
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

**Acceptance criteria**
- [ ] All open questions above have a documented decision
- [ ] Data model for creature inventory and `WorldObject`/`LootSource` grid entities is defined
- [ ] Acceptance criteria for the implementation issue(s) derived from this discovery are written
