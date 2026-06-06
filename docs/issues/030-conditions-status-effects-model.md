# #30 · Conditions and status effects engine model
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** medium
**Tags:** rules, architecture

D&D 5e conditions (Poisoned, Paralyzed, Blinded, Charmed, etc.) are rule-modifying nodes that temporarily alter an entity's capabilities. The engine currently has no representation for them.

Design questions:
- Where are active conditions stored? In `entity.stats` map or a dedicated `conditions: [atom]` field?
- How does the rules engine check for active conditions before resolving actions (movement, attacks, saving throws)?
- Who applies and removes conditions — the Ruleset callback, a dedicated Conditions module, or the action resolver?
- How are conditions rendered on the SVG (icon overlay, colour shift, tooltip)?

This is a prerequisite for: saving throws, concentration spells, paralysis, death saves, and anything that makes combat tactically interesting beyond basic HP subtraction.

**Acceptance criteria**
- [x] Condition representation decided and entity struct updated — `entity.conditions: [atom]` list + `state.active_effects` registry on `Engine.State`
- [x] At least two conditions implemented end-to-end: Poisoned (disadvantage on attack rolls) and Incapacitated (enforced via `{:entity_is_incapacitated}` predicate at action-economy gating) — both in #42
- [ ] Conditions visible in the UI (icon or colour indicator on the affected entity) — deferred to #34 (active effect visual representation)
- [x] Ruleset callback contract documented — `State.apply_condition/4` and `State.remove_condition/3` are the canonical application API; condition modifiers are collected via `ModifierPipeline.collect_modifiers/3`
