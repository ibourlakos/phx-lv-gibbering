# #44 · Spell slots + class resource pools in `resources` map

**Status:** closed
**Closed:** 2026-06-05
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** rules, gameplay

No spell slot or class resource tracking exists. Spells can be cast without
consuming slots; class abilities can be used without charge.

Depends on #37 (runtime entity map extensions).

**Acceptance criteria**
- [x] `DnD5e.initial_resources/1` returns a `resources` map correctly populated from entity `class` and `level`: spell slot counts per level for Wizard; `rage_charges`, `second_wind`, `action_surge` for Barbarian/Fighter; empty map for classes with no tracked resources
- [x] `consume_resource(state, entity_id, resource_key)` decrements the charge; returns `{:ok, state}` or `{:error, :no_charges}`
- [x] `consume_spell_slot(state, entity_id, level)` decrements `spell_slots[level]`; returns `{:ok, state}` or `{:error, :no_slots}`
- [x] Short rest restores `second_wind` and `action_surge` for Fighter; long rest restores all spell slots
- [x] `mix precommit` passes
