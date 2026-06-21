# #138 · Stray yellow circle on active entity indicator

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-21
**Priority:** low
**Tags:** rendering, bug

The yellow circle that marks the active entity's turn appears in a
position that does not match the active entity, or persists/appears on
an entity that is not the active turn holder. Visually misleading.

Likely cause: the turn-indicator rendering uses a stale or mis-mapped
position when entities are depth-sorted or when the turn order changes.

**Acceptance criteria**
- [x] The yellow circle (or equivalent active-turn marker) renders
      exactly on the entity whose turn is current, as defined by
      `state.actor_id` or `State.active_hero_id/1`
- [x] The circle does not appear on any other entity
- [x] The circle disappears when no entity has the active turn (lobby phase)
- [x] `mix precommit` exits 0
