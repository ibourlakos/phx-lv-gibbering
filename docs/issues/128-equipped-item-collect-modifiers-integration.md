# #128 · Equipped item `collect_modifiers` integration

**Status:** closed
**Opened:** 2026-06-12
**Closed:** 2026-06-19
**Priority:** low
**Tags:** rules, architecture

Wire equipped items into the `RuleModifier` pipeline so that weapon and armor properties are applied via the same data-driven mechanism as race traits, class features, and conditions.

Currently `collect_modifiers/3` gathers from `[:race_traits, :class_features, :active_conditions]`. This issue adds `:equipped_items` as a fourth source. It reads `stats["equipped_weapon"]` and `stats["equipped_armor"]`, looks each key up in `Data.Items`, and returns that item's `modifiers: [%RuleModifier{}]` list.

Depends on: #126 (inventory data model), #40 (`RuleModifier` pipeline, closed).

**Acceptance criteria**
- [x] `Data.Items` item maps include a `modifiers: [%RuleModifier{}]` field (derived at read time in `all/0` and `get/1`); finesse weapons grant `{:choose_attack_ability, [:dexterity, :strength]}`; body armour grants `{:override_ac_formula, {:armor, category, base_ac}}`; shields grant additive `{:add_bonus, :ac, 2}`; everything else has `modifiers: []`
- [x] `collect_modifiers/3` gains an `:equipped_items` source: `modifiers_for_context/2` reads the embedded `stats["equipped_weapon"]`/`stats["equipped_armor"]` maps, extracts each `"key"`, fetches it from `Data.Items`, and appends its `modifiers`. Unknown keys (e.g. `"no_armor"`) and empty slots contribute nothing. Trigger relevance is left to the existing trigger filter (consistent with the other passive sources), rather than special-casing the source by trigger.
- [x] `DnD5e.Stats.armor_class/1` and `DnD5e.Stats.attack_bonus/2` pass unchanged — the new `:choose_attack_ability`/`:override_ac_formula` effects are collected but not yet folded by `apply_modifiers` (transitional coexistence).
- [x] Unit tests added: fighter in chain mail surfaces the override-AC-formula modifier; rogue with a rapier surfaces the DEX-choice modifier on melee attack; plus shield, non-finesse, unknown-key, and no-stats cases. `Data.Items` modifier shape covered in `items_test.exs`.
- [x] `mix precommit` passes (783 tests, 0 failures).
