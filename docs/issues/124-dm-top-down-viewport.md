# #124 · DM top-down viewport: toggle, full-viewport switch, entity circles, grid labels
**Status:** open
**Opened:** 2026-06-12
**Priority:** low
**Tags:** rendering, ui, architecture

Implement the DM top-down view: a full-viewport projection switch accessible only to the DM, rendering entities as colored circles with labels, with a grid coordinate overlay and hover tooltip for precise placement.

Derived from #101 (DM top-down projection mode discovery). Depends on #123 (Projection behaviour).

## Scope

**Toggle**

- Toggle button in the DM panel (visible only to `membership_role: :dm`)
- Updates `socket.assigns.projection` between `:isometric` and `:top_down`
- Client-side only: no server message sent, no PubSub broadcast, players unaffected

**Full-viewport switch**

- When `projection: :top_down`, the scene SVG re-renders using `Projection.TopDown` via the parameterised pipeline from #123
- Same viewport/viewBox as isometric mode; pan/zoom hook continues to work unchanged
- DM panel and HUD overlays remain visible

**Entity representation**

- Entities rendered as colored SVG circles (radius ~0.4 × tile_w) centred on their tile
- Color by role: PC → blue, monster → red, NPC → grey (matching existing color conventions)
- Short label inside or below the circle: entity name truncated to ~6 characters
- No sprite compositor involved — this is a separate, simpler render path

**Coordinate display (DM-only, top-down mode only)**

- Grid label overlay: `{x, y}` text at every 5th tile intersection, low-contrast, non-interactive
- Hover tooltip: mousing over any tile shows its exact `{x, y}` world coordinate

**Notes**

- Players' sockets are always `projection: :isometric`; the DM toggle writes only to the DM's own socket assigns
- Top-down mode is a placement tool — drag-to-move entity interaction in top-down mode is out of scope for this issue (DM can still move entities via existing isometric controls after toggling back)

**Acceptance criteria**
- [ ] DM panel shows a toggle button; players do not see it
- [ ] Toggling updates `socket.assigns.projection`; scene re-renders with `Projection.TopDown`
- [ ] Entities render as colored circles with short labels in top-down mode
- [ ] Grid coordinate labels appear every 5 tiles
- [ ] Hover tooltip shows `{x, y}` for the tile under the cursor
- [ ] Toggling back to `:isometric` restores full sprite rendering
- [ ] Players' views are unaffected by the DM's toggle at any point
- [ ] LiveView tests cover: DM can toggle, player cannot toggle, projection switch re-renders correctly
