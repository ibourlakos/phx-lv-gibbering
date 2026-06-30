# #155 · Composable entity appearance pipeline — archetype render system v1
**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-21
**Priority:** low
**Tags:** rendering, architecture

Implement the composable appearance system from brainstorm #23: skeleton archetypes,
socket-offset model, 4-way facing, and the proportion constraint. This replaces the
current placeholder shape rendering for entities.

**Scope:**
- Define the `AppearanceArchetype` data model: archetype atom, socket map
  (`%{socket_name => %{north: {dx,dy}, south: …, east: …, west: …}}`)
- Implement 4-way facing selection and West = East + `scaleX(-1)` flip
- Implement layer ordering by facing (shield behind body when facing North, etc.)
- Enforce the 2–2.5× tile height proportion rule for all biped-upright entities
- Size category scales tile footprint: 1×1 medium, 2×2 large, 3×3 huge — socket
  offsets scale proportionally
- Swarm archetype: single SVG shape token, no socket model
- Elemental/amorphous archetype: single animated SVG path for v1
- Structure archetype: multi-tile, no facing, no sockets; interior deferred to #158

**Out of scope:** content creator authoring tool for sockets (deferred with #85),
structure interiors (deferred with #158), procedural swarm clusters.

**Acceptance criteria**
- [x] `AppearanceArchetype` struct defined with socket map and facing variants
- [x] Render function resolves entity archetype → layer list for given facing direction
- [x] West facing uses East asset with `transform="scaleX(-1)"`
- [x] Layer order changes correctly per facing (shield example)
- [x] Biped-upright entities render at 2–2.5× tile height
- [x] Size category footprint scaling applied (large = 2×2 tile origin)
- [x] At least one non-humanoid archetype (quadruped or insectoid) rendered in dev seeds
- [x] `mix precommit` passes
