# Brainstorm #23 — Composable entity appearances

**Status:** open

## Context

All entity rendering is currently placeholder shapes. Before committing to a
rendering approach, we need a composable appearance model that covers the full
range of entity types in the engine — PCs, NPCs, monsters, structures, vehicles,
and swarms — without locking us into a skeleton that only works for humanoids.

## Skeleton archetype vocabulary

Every rendered entity must declare one archetype. The archetype determines which
slots exist, their anchor offsets, and how facing direction maps to layer order.

| Archetype | Examples | Head position | Notes |
|---|---|---|---|
| **biped-upright** | Human, elf, goblin, tiefling | Above torso | Standard paper-doll layers |
| **quadruped** | Wolf, horse, lion, bear | Forward on horizontal axis | Back, torso, legs, head-forward |
| **draconic** | Dragon (4L+2W), wyvern (2L+2W) | Forward on long neck | Wing pair is a distinct layer |
| **serpentine** | Snake, purple worm, naga | Tip of elongated body | No limb slots; body is a path |
| **avian-biped** | Harpy, aarakocra | Above torso | Wing pair replaces or augments arms |
| **insectoid** | Spider, carrion crawler | Low and forward | 6–8 leg slots; carapace layer |
| **aberration** | Beholder, gibbering mouther | Radial or absent | No canonical facing; may rotate freely |
| **giant-construct** | Golem, animated statue, giant | Above torso | Biped-upright but spans 2×2+ tiles |
| **swarm** | Rat swarm, insect cloud | None | Single token, no individual anatomy |
| **plant** | Treant, shambling mound | Top or absent | Root anchor; slow or sessile |
| **structure** | Building, wall segment, tower | None | Multi-tile; has interior layer; no facing |
| **vehicle** | Wagon, ship | None | Multi-tile; mobile; no body parts |
| **elemental-amorphous** | Fire elemental, ooze, water weird | None | Shape shifts; no fixed sockets |

Structures deserve special treatment: they do not face, they span multiple tiles,
they have a roof layer that occludes interiors (ties to elevation + fog of war),
and they may have interactive sub-elements (doors, windows) that are separate
objects, not equipment slots.

## The socket-offset model

Every archetype defines named sockets with `(dx, dy)` offsets relative to a
shared origin (bottom-center of the entity's tile footprint). Child parts are
drawn at their parent socket's coordinates, so a hat drawn around `(0,0)` will
snap to whatever the body's `head_socket` is — regardless of race or archetype.

```
body.head_socket(:south)  → {0, -45}   # humanoid, facing viewer
body.head_socket(:east)   → {35, -20}  # quadruped, head extends forward
```

Content creators define socket coordinates per archetype + facing when they
author a body asset. Head/hat/weapon assets are agnostic — they trust the socket.

## 4-way facing and the flip optimization

Render assets for N, S, E, W only. Diagonal movement snaps to the dominant
or last cardinal direction. West-facing = East-facing with `transform="scaleX(-1)"`,
halving the asset authoring load.

Layer order changes with facing (e.g., shield is drawn last when facing South
because it's in front, first when facing North because it's behind the body).

## Character proportions

Characters should stand 2–2.5× the visual height of a single floor tile diamond
to achieve the Don't Starve Together "tall on flat ground" silhouette. This is a
fixed design constraint, not a per-entity variable.

## Sub-tile visual props

Decorative elements smaller than a tile (a scattered coin, a chip of stone) are
not entities — they have no game coordinate, no archetype, and no socket model.
They are SVG fragments positioned with a sub-tile pixel offset inside the tile
they visually belong to. This is rendering only; game logic does not address them.
Pickupable items resting on a tile use the tile's integer coordinate as their
game address; their visual rendering may be offset within the tile for aesthetics.

## Decisions

| Question | Decision |
|---|---|
| Content creator socket exposure? | Deferred with #85 (content creation tools). Socket authoring belongs in the appearance editor, not the engine. |
| Structure interiors — sub-scene or elevation layer? | Elevation layer: interior tiles rendered at z > 0 inside the structure footprint. No separate LiveView for interiors. Deferred to elevation work (#158). |
| Swarms — single shape or procedural cluster? | Single SVG shape for v1. Procedural scattered cluster is a visual polish deferral. |
| Archetype + size category? | Size category scales the tile footprint (1×1 medium, 2×2 large, 3×3 huge). Socket offsets scale proportionally. No new archetype needed per size. |
| Elemental/amorphous render? | Single animated SVG path (morphing shape) for v1. Fully procedural is deferred. |

## Issues Opened

| Issue | Title | Status |
|---|---|---|
| [#155](../issues/155-composable-entity-appearance-pipeline.md) | Composable entity appearance pipeline — archetype render system v1 | open |

This brainstorm will be deleted when #155 is closed.
