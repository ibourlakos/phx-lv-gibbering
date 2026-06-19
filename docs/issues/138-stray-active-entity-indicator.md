# #138 · Stray yellow circle on active entity indicator

**Status:** open
**Opened:** 2026-06-19
**Priority:** low
**Tags:** rendering, bug

The yellow circle that marks the active entity's turn appears in a
position that does not match the active entity, or persists/appears on
an entity that is not the active turn holder. Visually misleading.

Likely cause: the turn-indicator rendering uses a stale or mis-mapped
position when entities are depth-sorted or when the turn order changes.

**Acceptance criteria**
- [ ] The yellow circle (or equivalent active-turn marker) renders
      exactly on the entity whose turn is current, as defined by
      `state.actor_id` or `State.active_hero_id/1`
- [ ] The circle does not appear on any other entity
- [ ] The circle disappears when no entity has the active turn (lobby phase)
- [ ] `mix precommit` exits 0
