# #30 · Conditions and status effects engine model
**Status:** open
**Opened:** 2026-06-05
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
- [ ] Condition representation decided and entity struct updated
- [ ] At least two conditions implemented end-to-end: Poisoned (disadvantage on attack rolls) and Incapacitated (can't take actions)
- [ ] Conditions visible in the UI (icon or colour indicator on the affected entity)
- [ ] Ruleset callback contract documented for condition application/removal
