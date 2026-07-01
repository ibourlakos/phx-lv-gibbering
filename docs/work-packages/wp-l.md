# WP-L · DM Projection & Top-Down Viewport
**Status:** active
**Added:** 2026-06-14

Derived from closed discovery #101. Sequence: rendering infrastructure → DM UI.

**Gated on WP-S (#169):** the `Projection` behaviour and `Projection.Isometric` implementation are introduced in Phase 2b (#169) as part of the engine extraction — `IsoProjection` is moving to the engine anyway, so the behaviour is defined at the same time. #123 is therefore closed by #169 and does not need a separate branch. #124 becomes available once WP-S is complete.

## Dependency chain

```
WP-S / #169 (Projection behaviour introduced in engine extraction) → #124 (DM top-down viewport)
```

## Issues

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#123](../issues/123-projection-behaviour-modules.md) | `Projection` behaviour: Isometric + TopDown modules, renderer audit | low | — Closed by #169 |
| [#124](../issues/124-dm-top-down-viewport.md) | DM top-down viewport: toggle, entity circles, grid labels, hover tooltip | low | WP-S (#169) |

## Sequencing

#123 is absorbed into Phase 2b (#169): defines `GibberingEngine.Projection` behaviour, renames `IsoProjection` → `Projection.Isometric`, and threads the projection parameter through the render pipeline. #124 follows once WP-S is complete — adds the DM toggle, switches the scene SVG to use `Projection.TopDown`, and adds entity circles, grid labels, and hover tooltip.
