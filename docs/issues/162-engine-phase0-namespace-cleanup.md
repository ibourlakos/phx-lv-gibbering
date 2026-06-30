# #162 · Engine decomposition Phase 0 — namespace cleanup

**Status:** open
**Opened:** 2026-06-29
**Priority:** low
**Tags:** architecture

Move generic engine types out of D&D namespaces and document the seam in module docs. Pure rename/move — no structural or behavioral change.

Derived from the engine decomposition plan in [`docs/architecture/engine-decomposition.md`](../architecture/engine-decomposition.md). Phase 0 is prerequisite for Phase 1 (#163).

**Changes:**

1. Move `Rulesets.DnD5e.RuleModifier` → `Gibbering.Engine.RuleModifier`. The struct contains no D&D logic — it's the generic atomic rule atom used by any ruleset. Update all call sites.

2. Split the `Gibbering.Events.Scene.*` namespace:
   - Generic events stay as `Gibbering.Events.Engine.*`: `EntityMoved`, `TurnAdvanced`, `PhaseTransitioned`, `HpAdjusted`, `ResourceConsumed`, `ContainerOpened`, `RollRequired`, `SessionEnded`, `LogEntryRevealed`, `LogEntryHidden`, `BroadcastSent`, `WhisperDelivered`
   - D&D events move to `Gibbering.Events.DnD5e.*`: `AttackResolved`, `DamageDealt`, `SpellCast`, `ConditionApplied`, `ConditionRemoved`, `ItemEquipped`, `ItemTaken`

3. Add `@moduledoc` to all event structs. Each doc must state: which layer the event belongs to (engine or D&D), who emits it, and what it signals.

**Acceptance criteria**
- [ ] `Gibbering.Engine.RuleModifier` exists; old module removed; all callers updated
- [ ] Generic events live under `Gibbering.Events.Engine.*`; D&D events under `Gibbering.Events.DnD5e.*`; old aliases removed
- [ ] All event struct modules have a `@moduledoc` explaining layer, emitter, and signal
- [ ] `mix precommit` passes
