# #185 · `take_all_items` can silently destroy items on partial failure

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** bug, gameplay

`SceneServer`'s `take_all_items` reduces over a container's items, calling
`Inventory.take_item` per item. On `{:error, _}` for an individual item,
the reduce just carries forward the unchanged accumulator — the failed
item is not retained or reported anywhere. Separately, the container's
`stats.items` is wiped unconditionally (`put_in(container, [:stats,
"items"], [])`) regardless of which individual `take_item` calls actually
succeeded.

Net effect: an item whose `take_item` call errors is never added to the
taking actor (dropped by the error branch) **and** is removed from the
container anyway (unconditional wipe) — the item instance is destroyed
with no event emitted and no recovery path.

Currently latent (existing code paths pass exact quantities so the error
branch isn't hit in practice), but fragile — any future validation added
to `Inventory.take_item` (e.g. weight limits, item-specific pickup rules)
will start silently deleting player items.

**Acceptance criteria**
- [ ] Only successfully-transferred items are removed from the container;
      failed items remain
- [ ] A partial-failure result is surfaced (event and/or return value),
      not silently dropped
- [ ] Regression test: simulate a `take_item` failure mid-loop, assert the
      failed item is still in the container afterward and no item count
      changes for it
- [ ] `mix precommit` passes

**Source:** identified via external code review (GLM/ZAI), verified against
code before filing.
