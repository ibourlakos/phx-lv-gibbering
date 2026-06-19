# #158 · Elevation model — integer Z, render sort, iso_project formula, staircase objects
**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** architecture, rendering, gameplay
**Depends on:** #156 (coordinate model — elevation is part of game grid; iso_project formula)

Implement the logical elevation axis from brainstorm #25.

**Logical Z:**
- Entities carry an `elevation` integer (0 = ground; 1 = raised platform; 2 = rooftop)
- `Engine.State` entity coordinates become `{x, y, elevation}` triples
- Movement between elevations requires a staircase object (see below) or fly speed

**SVG render sort:**
```
sort_value = x + y + (elevation * weight)
```
Weight must be large enough that elevation 1 always renders above all elevation 0 tiles.
Concrete: `weight = map_x_extent + map_y_extent` ensures no overlap.

**Projection:**
`iso_project/4` updated to incorporate elevation:
```
screen_y -= elevation * (tile_h / 2)
```
(Already specified in #156; this issue wires it into the render pipeline.)

**Staircase objects:**
- Object entities may carry `connects_elevation: {from_level, to_level}`
- Traversability allows moving from `elevation: from_level` to `elevation: to_level` through this object
- Cost: climb multiplier (2× per foot of elevation change)
- Staircase objects are bidirectional unless `one_way: true`

**Out of scope:** falling mechanics, structure interiors, elevation-aware movement overlay colour.

**Acceptance criteria**
- [ ] Entity records carry `elevation` field (default 0); migration updates existing rows
- [ ] `Engine.State` stores and queries entity positions as `{x, y, elevation}`
- [ ] Render sort order incorporates elevation weight
- [ ] `iso_project/4` shifts `screen_y` by elevation offset
- [ ] Staircase object type recognisable from entity stats (`connects_elevation` key)
- [ ] Movement engine allows elevation transitions via staircase objects at climb cost
- [ ] At least one elevated tile and one staircase in dev seeds
- [ ] `mix precommit` passes
