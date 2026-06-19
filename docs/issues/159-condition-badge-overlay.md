# #159 · Condition badge overlay on entity tokens
**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** rendering, gameplay, ui

Render small icon badges on entity tokens for active conditions. The engine-side
condition struct and runtime application exist (#42 closed). This issue adds the
visual layer.

**Scope:**
- Each condition in `entity.conditions` renders a small badge icon on the token
- Badges stack (up to a sensible cap before truncating with a "+N" label)
- Badge position: bottom edge or corner of the entity tile footprint, consistent
  across all entity types
- Initial set: `prone`, `blind`, `deafened`, `grappled`, `restrained`, `poisoned`,
  `incapacitated`, `stunned`, `unconscious`, `dead`
- `movement_exhausted` is a pseudo-condition (not a D&D condition) rendered in the
  same badge layer — triggered when `movement_remaining == 0` at any point during
  a turn, cleared on turn start

**DM vs. player visibility:**
- Most conditions are visible to all roles (they represent observable fiction)
- Conditions on hidden entities are not shown to players (entity is hidden entirely)
- Rule: badge visibility follows entity visibility

**Acceptance criteria**
- [ ] Condition badge SVG fragment rendered per active condition on entity token
- [ ] `movement_exhausted` pseudo-condition badge appears when `movement_remaining == 0`
- [ ] `movement_exhausted` badge cleared at turn start (on `advance_turn`)
- [ ] Badges stack with a "+N" overflow label beyond a configurable max (default 3 visible)
- [ ] Badge position is consistent across biped-upright, quadruped, and swarm archetypes
- [ ] Badges not shown for hidden entities in player view
- [ ] At least `prone`, `grappled`, and `movement_exhausted` have distinct icons in dev seeds
- [ ] `mix precommit` passes
