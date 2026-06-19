# Brainstorm #27 — Coordinate model and spatial addressing

**Status:** open

## Context

The current coordinate model is `(x, y)` integer tile coordinates at ground level.
Several features in the pipeline — elevation, teleportation, multi-story buildings,
sub-tile visual props, and the tile granularity question — all put pressure on
this model. We need to define the canonical spatial addressing scheme before
it becomes load-bearing in multiple systems.

## Tile granularity and the D&D scale

One tile = 5 feet (the D&D 5e standard square). This is the fundamental movement
and range unit and must not be subdivided for game logic — breaking it would
invalidate all rules math (movement costs, spell radii, adjacency, reach).

Sub-tile precision is a **visual concern only**: a small stone or decorative prop
can be rendered at an offset within its tile using SVG fractional coordinates,
but its game address remains the integer tile coordinate it sits on.

## Coordinate spaces

The engine needs three distinct spaces:

### 1. Game grid — `{x, y, elevation}`

Integer coordinates. The canonical address for all game-logic purposes:
entity positions, spell targeting, movement ranges, area of effect.

- `x`, `y`: tile column and row
- `elevation`: integer level (0 = ground, 1 = raised platform, 2 = rooftop, etc.)
- All traversability queries, range calculations, and targeting use this space

### 2. SVG render space — `{screen_x, screen_y}`

Float pixel coordinates derived from game grid coordinates via the isometric
projection function. Used only by the rendering layer; never stored as game state.

```
{screen_x, screen_y} = iso_project(x, y, elevation, layout, tile_size)
```

Sub-tile visual offsets (decorative props) live only in this space.

### 3. Surface addresses — `{object_id, surface_point}`

For objects and structures that expose a landable surface distinct from their
tile footprint — a rooftop, the top of a boulder, a raised platform that is
itself an object. These surfaces need addressable coordinates for teleportation
destinations even if no walking path reaches them.

A surface address resolves to a game grid coordinate `{x, y, elevation}` at
query time; it is not a separate runtime coordinate but a way to reference
"the top of this object" without hard-coding the elevation.

## Interior spaces

A building's interior is not reachable by ground-level walking (it's enclosed
by walls and a door). Yet it must be:
- A valid teleportation destination (Dimension Door to a room you've visited)
- A valid entity position (creatures inside the building have positions)
- Subject to its own fog of war (interior is hidden until explored or visible)

Two candidate models:
- **Interior as elevated layer**: interior floor tiles exist at a negative or
  fractional elevation level within the structure's tile footprint. Simple but
  requires elevation to support non-integer or sub-zero values.
- **Interior as sub-scene**: the building has a separate tile grid rendered as
  a nested or modal view. Cleaner separation but adds a scene-transition system.

## Teleportation destination validity

Teleportation bypasses traversability but requires a valid *destination*:
1. The destination coordinate must resolve to a landable surface
2. The tile/surface must be unoccupied by blocking objects or entities
3. Most teleportation spells additionally require line of sight from origin

The "landable" check is: does a surface exist at `{x, y, elevation}` that a
creature of the mover's size can stand on? This is distinct from walkability
(which requires a connected path) and must be queryable independently.

A rooftop with no staircase is landable (valid teleport target) but not walkable
(no movement path exists). The engine must not conflate the two.

## The edge coordinate model

Walls and doors occupy edges between tiles, not tile centers. An edge is
addressed as `{tile_coord, direction}`:

```
{x: 2, y: 3, direction: :north}  →  the north edge of tile (2,3)
                                     = the south edge of tile (2,2)
```

Edge queries must be normalised so `{2,3,:north}` and `{2,2,:south}` resolve
to the same edge. Walls and doors are stored once per edge, not duplicated.

## Open questions

- Should elevation be integers only, or rational numbers (e.g., `0.5` for
  a half-step platform)? Integer levels are simpler; half-steps may be needed
  for certain terrain types.
- How are surface addresses stored? As a derived property of the Object record,
  or as explicit rows in a `surfaces` table?
- Interior spaces: elevated layer or sub-scene? This is probably the biggest
  unresolved question in the spatial model.
- How does the projection function `iso_project/4` handle elevation? A raised
  platform should shift `screen_y` upward; the exact formula determines how
  high one elevation level appears on screen.
- Is there a maximum map size? Large maps with many entities may stress
  the SVG render; this may inform whether we need spatial partitioning for
  rendering (only render tiles in or near the viewport).

## Cross-references

- Related: brainstorm #25 (elevation — logical Z is part of the game grid)
- Related: brainstorm #26 (tile occupancy — traversability queries use game grid coords)
- Related: brainstorm #24 (isometric layout — determines the iso_project formula)
- Related: brainstorm #23 (entity appearances — rendering uses SVG render space)
