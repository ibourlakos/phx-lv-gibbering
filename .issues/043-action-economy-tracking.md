# #43 · Action economy tracking + `advance_turn` reset

**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** rules, gameplay

Without tracking action economy, the engine cannot enforce the rule that each
entity gets one action, one bonus action, one reaction, and a movement budget
per turn. Actions can be taken multiple times without restriction.

Depends on #37 (runtime entity map extensions).

**Acceptance criteria**
- [ ] `consume_action(state, entity_id, slot)` where `slot :: :action | :bonus_action | :reaction` marks the slot as `:spent`; returns `{:ok, state}` or `{:error, :already_spent}`
- [ ] `consume_movement(state, entity_id, feet)` deducts from `movement_remaining`; returns `{:ok, state}` or `{:error, :insufficient_movement}`
- [ ] `State.advance_turn/1` resets `action_economy` to all `:available` and `movement_remaining` to entity speed for the next entity in turn order
- [ ] Engine validates action economy before executing attacks, spell casts, and moves; invalid actions return `{:error, reason}` rather than panicking
- [ ] `mix precommit` passes
