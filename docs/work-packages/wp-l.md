# WP-L · DM Projection & Top-Down Viewport
**Status:** active
**Added:** 2026-06-14

Derived from closed discovery #101. Sequence: rendering infrastructure → DM UI.

WP-S is complete (#169 introduced the `Projection` behaviour and renamed `IsoProjection` → `Projection.Isometric`). #123 was closed by #169. #124 is now unblocked.

## Dependency chain

```
WP-S / #169 (Projection behaviour — complete) → #124 (DM top-down viewport — active)
```

## Issues

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#123](../issues/123-projection-behaviour-modules.md) | `Projection` behaviour: Isometric + TopDown modules, renderer audit | low | Closed by #169 |
| [#124](../issues/124-dm-top-down-viewport.md) | DM top-down viewport: toggle, entity circles, grid labels, hover tooltip | low | — |

## Sequencing

#123 is absorbed into Phase 2b (#169): defines `GibberingEngine.Projection` behaviour, renames `IsoProjection` → `Projection.Isometric`, and threads the projection parameter through the render pipeline. #124 follows once WP-S is complete — adds the DM toggle, switches the scene SVG to use `Projection.TopDown`, and adds entity circles, grid labels, and hover tooltip.
