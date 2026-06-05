# Isometric Rendering Depth and Viewport

**Topic:** Rendering architecture challenges introduced by DST-level sprite fidelity, elevation (Z axis), volumetric spell effects, and viewport zoom/pan.

**Status:** exploration

---

## Context

The decision to target Don't Starve Together fidelity for character sprites (see brainstorm #07, issue #53) surfaces three compounding rendering concerns that the current flat 2D SVG pipeline does not address:

1. **Viewport zoom/pan** — DST-detail sprites need screen real estate to read clearly, which limits how many tiles fit at once. Maps large enough for meaningful tactical play need zoom and pan.
2. **Elevation** — Characters on balconies, raised platforms, or multi-level terrain require a Z axis in both the projection math and the depth-sorting logic.
3. **Volumetric effects** — Spells like Silence, Fog Cloud, and Web occupy a 3D volume. Rendering them as flat tile highlights loses the spatial information players need to make tactical decisions.

These three are distinct problems but they interact — elevation affects how volumetric effects are clipped, and both affect how the camera/viewport should behave.

---

## A. Viewport Zoom and Pan

### The problem

At DST sprite fidelity, a readable character sprite needs roughly 48–64 px wide on screen. The current tile size (64×32 px) barely fits that. A 20×20 tactical map at that scale would require ~1280×640 px minimum — already straining a standard browser viewport, and leaving no room for UI chrome.

Two zoom modes are needed:

- **Tactical (zoomed in):** full sprite detail visible; fewer tiles on screen (~10×10); used for active combat
- **Overview (zoomed out):** sprites simplified or silhouetted; more map visible; used for exploration or DM prep

### SVG approach

SVG `viewBox` manipulation is the clean solution — changing the `viewBox` scales all vector content uniformly with no blurriness. No CSS transforms, no canvas redraw.

```
zoom in  → smaller viewBox → same SVG content appears larger on screen
zoom out → larger viewBox  → more content visible, sprites appear smaller
```

Pan is a `viewBox` origin offset. At full zoom-out (whole map visible) pan is unnecessary. At zoom-in, pan follows the active character or is mouse/keyboard driven.

### Per-player vs shared camera

A key unresolved question: does each player control their own camera, or does everyone follow a shared view?

- **Shared view (tabletop model):** the DM or the "active turn" drives the camera. Simple, but passive players lose agency.
- **Per-player camera:** each LiveView client has its own `viewBox` state. Players can pan freely. The DM has a separate god-view. More complex but better player experience.

Per-player camera is the more natural choice for an online async game. It means `viewBox` state lives in the LiveView socket assigns, not in the `SceneServer` — it is client-local, not broadcast.

### Minimap

A zoomed-in view naturally calls for a minimap — a fixed small SVG overlay rendering the whole map at low detail, with a rectangle showing the current viewport. Clickable to pan. Not essential for MVP but worth designing for from the start so the architecture supports it.

### Zoom and sprite detail levels

At very low zoom, DST-level sprite detail becomes noise. Two options:

- **LOD (Level of Detail):** swap in a simplified silhouette sprite below a zoom threshold
- **Accept the noise:** small but coherent sprites still read as distinct characters by silhouette alone

LOD is more work but a better experience. Worth noting as a forward design constraint on #53.

---

## B. Elevation (Z Axis)

### The problem

The current projection is flat — all entities sit at `z = 0`. A character on a balcony or raised platform needs to appear higher on screen and interact correctly with depth sorting.

### Projection change

The current formula:

```
sx = (x - y) * tile_w/2 + origin_x
sy = (x + y) * tile_h/2 + origin_y
```

With a Z axis:

```
sx = (x - y) * tile_w/2 + origin_x
sy = (x + y) * tile_h/2 - z * tile_h + origin_y
```

Each Z level shifts the entity up by `tile_h` pixels (32 px). A balcony at `z = 1` renders one tile-height above the floor.

### Depth sorting

The current `x + y` sort breaks with elevation. An entity at `(3, 3, 1)` and one at `(5, 5, 0)` may overlap in screen space. A robust sort key needs to account for Z:

```
sort_key = x + y + z * map_size   # ensures higher Z always sorts above same x+y
```

This is a simplification — edge cases exist near stairways or ramps where entities at different elevations genuinely overlap — but it handles the common case cleanly.

### Tile elevation data

Each tile gains a `z` integer. The `grid_tiles` data model needs this field. Elevated tiles also need visual representation — a "wall" face below the tile surface to show the platform height, not just a floating diamond.

### Distance and line of sight

D&D 5e uses a simplified 3D distance rule: when counting squares, every second diagonal (including diagonals on the Z axis) costs 2 squares instead of 1. The existing Chebyshev movement rules (issue #7) need extension to 3D for elevation scenarios.

Line of sight is the harder problem — does a wall at `z = 1` block a spell cast from `z = 0`? This requires a 3D LOS raycast, not just 2D tile adjacency checks.

---

## C. Volumetric Spell Effects

### The problem

Spells like Silence (20 ft radius sphere), Fog Cloud (20 ft radius sphere), Web (20 ft cube), and Cloudkill (20 ft radius sphere, moves) occupy a 3D volume. Rendering them as a flat coloured tile overlay loses:

- The height of the effect (a Silence sphere is 40 ft tall — 8 tiles high)
- The boundary at different elevations
- The sense of enclosure that matters tactically ("am I inside this?")

### Pseudo-3D representation in isometric SVG

A sphere in 2:1 dimetric projects as a specific ellipse. With a height band added, it reads as volumetric:

```
top cap     → filled ellipse at the top elevation of the sphere
side band   → parallelogram connecting top and bottom ellipses
bottom cap  → filled ellipse (often occluded by the ground)
```

The opacity should be low (20–30%) so entities inside are still visible, but the boundary is clear.

A cube (Web) projects as a hexagonal prism in isometric — three visible faces (top, left-front, right-front), each a parallelogram.

### Interaction with entities

An entity inside a volumetric effect should appear partially behind it — the effect wraps around them spatially. This requires the effect to be rendered in the depth-sort pass as a semi-transparent element at a specific `x+y+z` sort position, not as a fixed overlay above everything.

### Effect rendering layer

The SVG layer stack gains an **effects layer** between entities and the move overlay:

```
1. Ground tiles
2. Tile decorations (depth-sorted)
3. Volumetric effects (depth-sorted, semi-transparent)
4. Entities (depth-sorted)
5. Move overlay
6. Selection highlight
```

Volumetric effects themselves are depth-sorted by their centre point.

---

## Compound challenge

All three concerns interact:

- Elevation affects where volumetric effects clip (a Silence sphere centred at z=1 covers different tiles than one at z=0)
- Zoom level affects whether volumetric effect geometry is readable (at low zoom, effect boundaries become indistinct)
- Per-player camera means each client independently decides what is visible — the server sends full scene state; the client culls and renders its viewport

The current `IsoProjection` module (pure functions, no state) is the right abstraction to extend — projection math stays pure, only the `viewBox` state and elevation inputs change.

---

## Open Questions

- **Per-player camera or shared?** Per-player is better UX; shared is simpler to implement. Lean toward per-player with a "follow active token" default.
- **LOD for sprites at low zoom?** Needed for clean zoom-out, but adds art scope to #53.
- **Elevation in MVP?** Could defer elevation to a later issue while shipping zoom/pan first.
- **Stairways and ramps:** how does movement between Z levels work on the grid? (A stairway tile transitions z=0 → z=1 over one or two tiles.)
- **Minimap:** design for it from the start or bolt on later?
- **Effect clipping at elevation:** does a sphere effect show different tile footprints at each Z level it passes through? (Correct but complex.) Or just show the max footprint as a flat projection? (Simple but imprecise.)

---

## Issues to Open

- Discovery issue: viewport zoom/pan architecture (per-player `viewBox` state, zoom range, pan behaviour)
- Discovery issue: Z axis elevation — projection math, depth sorting, tile data model, 3D distance/LOS
- Discovery issue: volumetric effect rendering — sphere/cube projections, depth-sort integration, effect layer
- Follow-on to #53: LOD sprite detail levels tied to zoom threshold
