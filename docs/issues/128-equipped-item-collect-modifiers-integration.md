# #128 · Equipped item `collect_modifiers` integration

**Status:** open
**Opened:** 2026-06-12
**Priority:** low
**Tags:** rules, architecture

Wire equipped items into the `RuleModifier` pipeline so that weapon and armor properties are applied via the same data-driven mechanism as race traits, class features, and conditions.

Currently `collect_modifiers/3` gathers from `[:race_traits, :class_features, :active_conditions]`. This issue adds `:equipped_items` as a fourth source. It reads `stats["equipped_weapon"]` and `stats["equipped_armor"]`, looks each key up in `Data.Items`, and returns that item's `modifiers: [%RuleModifier{}]` list.

Depends on: #126 (inventory data model), #40 (`RuleModifier` pipeline, closed).

**Acceptance criteria**
- [ ] `Data.Items` item maps include a `modifiers: [%RuleModifier{}]` field for each entry; weapons with the `:finesse` property include a modifier granting DEX-or-STR attack ability choice; armor entries include an `{:override_ac_formula, formula}` or `{:add_bonus, :ac, n}` modifier as appropriate; items with no mechanical modifiers have `modifiers: []`
- [ ] `Gibbering.Rulesets.DnD5e.collect_modifiers/3` accepts a new `:equipped_items` source; when `trigger` is `:passive` or `:on_attack`, it reads `stats["equipped_weapon"]` and `stats["equipped_armor"]` from the entity, fetches each key from `Data.Items`, and appends their `modifiers`
- [ ] `DnD5e.Stats.armor_class/1` and `DnD5e.Stats.attack_bonus/2` still pass all existing tests unchanged (transitional coexistence)
- [ ] Unit tests: `collect_modifiers/3` with a fighter equipped with chain mail returns the AC modifier; with a rogue and a finesse weapon returns the DEX-choice modifier
- [ ] `mix precommit` passes
