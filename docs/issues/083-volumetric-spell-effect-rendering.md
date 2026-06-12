# #83 · Volumetric spell effect rendering

**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** Depends on #82 (Z-axis elevation), which is deferred. The first open question in this issue — "Does volumetric rendering depend on elevation to be meaningful?" — cannot be answered until the elevation brainstorm resolves. Un-defer after BS-82 settles.
**Priority:** low
**Tags:** discovery, rendering

Design pseudo-3D rendering of volumetric spell effects (Silence, Fog Cloud, Web, Cloudkill, etc.) in the isometric SVG pipeline.

Flat tile highlights lose height information — a Silence sphere is 40 ft tall (8 tiles). Players need spatial information to make tactical decisions ("am I inside this?").

**Pseudo-3D shapes in 2:1 dimetric:**
- **Sphere** → ellipse top cap + parallelogram side band + (usually occluded) bottom cap; 20–30% opacity so entities inside remain visible
- **Cube** → hexagonal prism projection: top face + two visible side faces, each a parallelogram

**Depth sort integration:** effects must participate in the depth-sort pass as semi-transparent elements, not as a fixed overlay above everything. An entity inside a volumetric effect should appear partially behind it.

**SVG layer stack (proposed):**
1. Ground tiles
2. Tile decorations (depth-sorted)
3. Volumetric effects (depth-sorted, semi-transparent)
4. Entities (depth-sorted)
5. Move overlay
6. Selection highlight

**Open questions to settle:**
- Does volumetric rendering depend on elevation (#82) to be meaningful, or can it ship flat (z=0 only) first?
- For sphere effects: show per-Z-level footprint projection, or show max footprint as flat projection? (Correct vs. simple.)
- Effect centre point storage: on the active effect record, or derived from the casting entity's position at cast time?
- Moving effects (Cloudkill moves each turn): how does movement interact with the depth sort?

**Acceptance criteria**
- [ ] All open questions have a documented decision
- [ ] SVG layer stack is finalised
- [ ] Sphere and cube projection geometry is documented (or deferred with reason)
- [ ] Depth-sort key for effect elements is specified
- [ ] Acceptance criteria for implementation issue(s) are written
