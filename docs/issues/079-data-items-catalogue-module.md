# #79 · `Data.Items` catalogue module

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** low
**Tags:** rules, gameplay

Static reference data for items — weapons, armor, and consumables — analogous to `Data.Spells`, `Data.Races`, and `Data.Classes`.

The item taxonomy from the D&D 5e semantic model:

- **Weapon** — `damage_dice`, `damage_type`, `weapon_category` (`:simple` / `:martial`), `weapon_properties` list (`:finesse`, `:heavy`, `:reach`, `:two_handed`, etc.)
- **Armor** — `armor_category` (`:light` / `:medium` / `:heavy` / `:shield`), `base_ac`, `stealth_disadvantage`, `strength_requirement`
- **Consumable** — `charges`, pointer to an action/spell effect (e.g. Potion of Healing)

All items share `name`, `weight_pounds`, `cost_gp`, `is_magical`, `requires_attunement`.

Seed data should cover the standard SRD weapon table, the standard armour table, and a handful of common consumables sufficient to equip a starter character of each class.

**Acceptance criteria**
- [x] `Gibbering.Data.Items` module with a `list/0` or `get/1` interface matching the pattern of `Data.Spells`
- [x] Weapon, armor, and consumable entries covering SRD starter gear referenced by `Data.Classes` starting equipment
- [x] Unit tests confirming key lookups, type fields, and absence of data errors
- [x] `mix precommit` passes
