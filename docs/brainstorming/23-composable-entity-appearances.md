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

## Open questions

- How does the content creator tool expose socket definition? (Click-on-canvas
  to place sockets per facing direction?)
- For structures: is the interior a sub-scene (separate LiveView) or a set of
  interior tiles rendered at a specific elevation layer?
- Swarms: is the token a single SVG shape or a procedurally scattered cluster
  of small shapes within the tile bounds?
- How does archetype interact with size category? A Huge biped-upright still
  uses the biped-upright slot set, just scaled to a 3×3 tile footprint.
- Do elemental/amorphous entities need a fully procedural render path, or can
  they be approximated with a single animated SVG path?

## Cross-references

- Related: brainstorm #24 (isometric layout — affects tile diamond height used
  in proportion calculations)
- Related: brainstorm #25 (elevation — structures have roof/interior layers)
- Related: brainstorm #26 (tile occupancy — structures and multi-tile objects
  affect traversability of multiple tiles simultaneously)
- Related: issue #132 (appearance catalogue — tile textures for terrain types)
