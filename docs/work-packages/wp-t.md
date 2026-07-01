# WP-T · Post-Phase 2 HUD Extraction
**Status:** active
**Added:** 2026-07-01

Gated on WP-S (Engine Decomposition Phase 2) completing. Formalises the engine's HUD concern by introducing `%GibberingEngine.HUD{}` and refactoring `GameLive` to render from it rather than reading raw engine state.

## Dependency chain

```
WP-S (complete) → #172 (HUD design) → #173 (GameLive HUD extraction)
```

## Issues

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#172](../issues/172-hud-struct-design.md) | HUD struct design — `%GibberingEngine.HUD{}` and computation site | medium | WP-S |
| [#173](../issues/173-gamelive-hud-extraction.md) | GameLive HUD extraction — render from `%HUD{}` | medium | #172 |

## Notes

- #172 is a discovery issue — do not start #173 until the struct shape and computation site are decided
- The DnD5e layer (`Rulesets.DnD5e`) is the reference HUD implementor; `GibberingTales.HUD.build/2` is the Tales-layer helper
- Phase 2b (#169) already cuts the `SpriteCompositor` → `ConditionBadge` coupling; this WP handles the remaining web-layer coupling to D&D-specific state
- WP-L's #124 (DM top-down viewport) is independent and can run in parallel once WP-S is done
