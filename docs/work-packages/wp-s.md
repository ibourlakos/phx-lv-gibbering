# WP-S · Engine Decomposition Phase 2 — Umbrella Conversion
**Status:** active
**Added:** 2026-07-01

Derived from discovery issue #167 (closed). Converts the project to a four-app Mix umbrella. Must complete before WP-T (post-Phase 2 HUD extraction) and before WP-L's #124 (DM top-down viewport) can begin.

## Dependency chain

```
#168 (scaffold) → #169 (engine) → #170 (tales domain) → #171 (web + admin)
```

## Issues

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#168](../issues/168-phase2a-umbrella-scaffold.md) | Phase 2a — Umbrella scaffold | high | — |
| [#169](../issues/169-phase2b-engine-extraction.md) | Phase 2b — Engine extraction | high | #168 |
| [#170](../issues/170-phase2c-tales-domain-extraction.md) | Phase 2c — Tales domain extraction | high | #169 |
| [#171](../issues/171-phase2d-web-admin-extraction.md) | Phase 2d — Web + Admin extraction | high | #170 |

## Notes

- #169 includes: `entities` → `actors` field rename in `Engine.State`; `AppearanceArchetype` → `ActorAppearance`; `IsoProjection` → `GibberingEngine.Projection.Isometric`; `Projection` behaviour introduction; `ConditionBadge` moved to `gibbering_tales` (cuts the D&D coupling from `SpriteCompositor`)
- #169 closes #123 (Projection behaviour — previously in WP-L; absorbed here since the module moves anyway)
- #171 includes all web-layer call site updates for renamed modules (follow naturally from code move)
- WP-L's #124 (DM top-down viewport) is gated on #169 completing
