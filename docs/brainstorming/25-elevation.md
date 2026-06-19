# Brainstorm #25 — Elevation

**Status:** open

## Context

The current tile model is flat (x, y). The engine will eventually need a vertical
axis: a hero climbing a rock, a caster standing on a raised platform, a dragon
perched on a tower. Elevation has implications for rendering order, movement cost,
line of sight, and how multi-story structures expose their interiors.

## Two distinct elevation concerns

### 1. Logical Z — game coordinate

A tile or object surface has an integer elevation level (e.g., `elevation: 0` for
ground, `elevation: 1` for a raised platform, `elevation: 2` for a rooftop).

- Entities occupy a `(x, y, elevation)` coordinate, not just `(x, y)`
- Movement between elevation levels requires climbing, jumping, flying, or a staircase
- Elevation affects movement cost: climbing typically costs 2× movement per foot
- Elevation affects line of sight: a higher entity can see over obstacles below

### 2. SVG render sort order — visual Z

SVG renders in document order; there is no CSS z-index for SVG children. The
painter's algorithm sort value must incorporate elevation:

```
sort_value = x + y + (elevation * weight)
```

The elevation weight must be large enough that a tile at elevation 1 always
renders on top of all tiles at elevation 0 at any (x, y).

## Interaction with structures

A building spanning tiles (1,1)–(3,3) at elevation 0 has a roof at elevation 1.
The roof layer must:
- Occlude the interior at normal zoom (you see the roof)
- Reveal the interior when a creature is inside or when the DM toggles roof
  visibility (ties to fog of war and DM override systems)

Interior tiles are effectively a separate tile layer at a sub-ground elevation
(e.g., `elevation: -1` relative to the building's base) or rendered as a
parallel scene. This is an open architectural question.

## Interaction with teleportation

A rooftop at elevation 1 must be a valid teleportation destination even if no
walking path reaches it. This means elevated surfaces must be addressable as
spatial coordinates independent of whether a walking path exists to them.
See brainstorm #27 for the coordinate model.

## Interaction with line of sight

- An entity at elevation 1 can see over a wall at elevation 0
- A wall at elevation 1 blocks line of sight from elevation 0 entities
- Elevation differences affect ranged attack modifiers (high ground advantage
  is a common homebrew rule, not RAW 5e but worth supporting)

## Decisions

| Question | Decision |
|---|---|
| Integer or continuous elevation? | Integers only (settled in #27). Half-step platforms use visual render offsets only. |
| Falling? | Deferred for v1 — no falling mechanic in minimum playable loop. File a follow-on issue when combat elevation becomes in-scope. |
| Stairs/ramps? | Objects with `connects_elevation: {from_level, to_level}` field. Movement through them deducts climb cost (2× per foot). |
| Interior spaces? | Deferred. Neither sub-elevation layer nor sub-scene chosen yet. Decision deferred to structure design. |
| Elevation in movement overlay? | Yes — tiles at elevation != mover's elevation show distinct cost colour (climb cost). Deferred to elevation render implementation in #158. |

## Issues Opened

| Issue | Title | Status |
|---|---|---|
| [#158](../issues/158-elevation-model.md) | Elevation model — integer Z, render sort, iso_project formula, staircase objects | open |

This brainstorm will be deleted when #158 is closed.
