# #101 · DM top-down projection mode (discovery)
**Status:** closed
**Opened:** 2026-06-06
**Closed:** 2026-06-12
**Priority:** low
**Tags:** discovery, rendering, architecture

The isometric perspective makes precise unit placement difficult for the DM on complex or crowded maps. A top-down orthographic view as an optional DM tool solves this without affecting what players see.

## Decisions

| Q | Decision |
|---|---|
| Viewport mode | **Full-viewport takeover.** Top-down is a temporary placement tool — an inset is too small for precise work on complex maps. DM toggles in, arranges units, toggles out. No minimap inset. |
| LiveView strategy | **Client-side projection switch.** `projection: :isometric \| :top_down` in the DM's socket assigns. Same GameLive process, same server state, different render function. Players are completely unaffected — the toggle never touches server state. |
| Entity representation | **Colored circles with short name label.** Top-down is a DM utility tool, not a player-facing view. Color-coding matches existing entity classes (PC / monster / NPC). Zero new art required. |
| Coordinate display | **Grid label overlay (every 5 tiles) + hover tooltip with exact `{x, y}`.** DM-only, visible only in top-down mode. Gives spatial context for multi-entity placement and precision for individual clicks. Players never see coordinates. |
| Projection architecture | **`Projection` behaviour with `project/2` callback** — world `{x, y}` in, screen `{sx, sy}` out. Two implementations: `Projection.Isometric` (existing math extracted) and `Projection.TopDown` (`{x * tile_w, y * tile_h}`). The tile store holds world coordinates only and never changes. The rendering pipeline accepts a projection module as a parameter. Any existing world/screen coordinate mixing in the current renderer is an audit/decouple task in #123. |

## Rendering path sketch

```
DM toggles top-down
  → socket.assigns.projection = :top_down
  → re-render scene SVG via TopDown.project/2 for all tile + entity positions
  → render entities as colored circles + short label (not full sprite compositor)
  → overlay grid label every 5 tiles
  → hover event returns {x, y} world coord as tooltip

DM toggles back
  → socket.assigns.projection = :isometric
  → re-render scene SVG via Isometric.project/2 (no server state change)
```

Players' sockets hold `projection: :isometric` permanently and are never notified of the DM's toggle.

## Implementation Issues

- [#123](123-projection-behaviour-modules.md) — `Projection` behaviour: define port, implement `Isometric` + `TopDown`, audit/decouple world/screen mixing in current renderer
- [#124](124-dm-top-down-viewport.md) — DM top-down viewport: toggle, full-viewport switch, entity circles, grid labels, hover tooltip

**Acceptance criteria**
- [x] All open questions answered with design decisions
- [x] Projection-agnostic tile store interface defined: world coords in store, projection applied at render time
- [x] Top-down rendering path sketched
- [x] Full-viewport takeover decided with rationale
- [x] SVG coordinate audit captured as follow-up in #123
- [x] Players confirmed unaffected: DM socket assign only, no server state change
