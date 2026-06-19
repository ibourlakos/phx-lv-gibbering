# WP-L · DM Projection & Top-Down Viewport
**Status:** active
**Added:** 2026-06-14

Derived from closed discovery #101. Sequence: rendering infrastructure → DM UI.

## Dependency chain

```
#123 (Projection behaviour: extract Isometric, implement TopDown) → #124 (DM top-down viewport)
```

## Issues

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#123](../issues/123-projection-behaviour-modules.md) | `Projection` behaviour: Isometric + TopDown modules, renderer audit | low | — |
| [#124](../issues/124-dm-top-down-viewport.md) | DM top-down viewport: toggle, entity circles, grid labels, hover tooltip | low | #123 |

## Sequencing

#123 first — defines the `Gibbering.Projection` behaviour, extracts existing isometric math into `Projection.Isometric`, implements `Projection.TopDown`, and threads the projection parameter through the render pipeline. #124 second — adds the DM toggle, switches the scene SVG to use `Projection.TopDown`, and adds entity circles, grid labels, and hover tooltip.
