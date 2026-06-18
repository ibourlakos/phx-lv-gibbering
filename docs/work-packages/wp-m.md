# WP-M · Inventory & Loot System
**Status:** active
**Added:** 2026-06-14

Derived from closed discovery #80. Sequence: data model → event engine + modifier integration.

## Dependency chain

```
#126 (data model: schema, JSONB fields, seeds) → #127 (event loop: SceneServer handlers + LiveView panel)
                                               → #128 (collect_modifiers: :equipped_items source)
```

## Issues

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#126](../issues/126-inventory-and-container-data-model.md) | Inventory and container data model | low | — |
| [#127](../issues/127-item-pickup-event-loop.md) | Item pickup event loop | low | #126 |
| [#128](../issues/128-equipped-item-collect-modifiers-integration.md) | Equipped item `collect_modifiers` integration | low | #126 |

## Sequencing

#126 closed (2026-06-14). #128 closed (2026-06-19). #127 is the only remaining issue — SceneServer event handlers (`:open_container`, `:take_item`, `:equip_item`), carry-weight logic, and the LiveView container panel.
