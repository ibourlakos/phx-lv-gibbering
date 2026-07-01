# #169 · Engine decomposition Phase 2b — Engine extraction

**Status:** open
**Opened:** 2026-07-01
**Priority:** high
**Tags:** architecture

Move all generic engine modules and their tests into `apps/gibbering_engine/`, verify the app compiles with no Ecto or Phoenix dependencies, and confirm `gibbering_tales` (empty at this stage) sees engine modules via the dep declaration.

Depends on #168. Predecessor to #170. Closes #123 (Projection behaviour).

---

## Modules to move

Based on the Generic Engine classification in engine-decomposition.md:

| Current namespace | New namespace |
|---|---|
| `Gibbering.Engine.*` | `GibberingEngine.Engine.*` (or `GibberingEngine.*`) |
| `Gibbering.Ruleset` | `GibberingEngine.Ruleset` |
| `Gibbering.Engine.RuleModifier` | `GibberingEngine.RuleModifier` |
| `Gibbering.EventBus` + adapters | `GibberingEngine.EventBus` + adapters |
| `Gibbering.Events.Engine.*` | `GibberingEngine.Events.*` |
| `Gibbering.Events.EventBatch` | `GibberingEngine.Events.EventBatch` |
| `Gibbering.Events.Upcaster` | `GibberingEngine.Events.Upcaster` |
| `Gibbering.Events.Decoder` | `GibberingEngine.Events.Decoder` |
| `Gibbering.Monitoring.*` | `GibberingEngine.Monitoring.*` |
| `Gibbering.Catalogue.Cache` | `GibberingEngine.Catalogue.Cache` |
| `Gibbering.Catalogue.Appearance` / `Style` | `GibberingEngine.Catalogue.Appearance` / `Style` |
| `GibberingWeb.IsoProjection` | `GibberingEngine.Projection.Isometric` |
| _(new)_ | `GibberingEngine.Projection` behaviour (`grid_to_screen/3`, `screen_to_grid/3`, `origin/3`) |
| `Gibbering.Engine.State.entities` field | rename to `actors` |
| `Gibbering.Engine.AppearanceArchetype` | `GibberingEngine.ActorAppearance` |

`Events.DnD5e.*` and `Events.Notification.*` are D&D-specific and stay out.
`ConditionBadge` moves to `gibbering_tales` — it is a D&D UI convention, not an engine primitive.

## Work

- Move modules into `apps/gibbering_engine/lib/`
- Rename module atoms (all `Gibbering.Engine.*` → `GibberingEngine.*` etc.)
- Rename `Engine.State.entities` → `Engine.State.actors` and update all call sites
- Rename `AppearanceArchetype` → `ActorAppearance`
- Rename `IsoProjection` → `Projection.Isometric`; define `Projection` behaviour with `grid_to_screen/3`, `screen_to_grid/3`, `origin/3` callbacks
- Move `ConditionBadge` to `gibbering_tales` (not `gibbering_engine`)
- Update all `alias` / `import` references in moved modules
- Move engine-layer tests to `apps/gibbering_engine/test/`
- Confirm `gibbering_engine`'s `mix.exs` deps list is Ecto/Phoenix-free (only `:telemetry`, `:jason`, etc.)
- Add `{:gibbering_engine, path: "../gibbering_engine"}` to `gibbering_tales/mix.exs`
- Fix any compilation errors in the remaining (not-yet-moved) code in tales/web/admin

## Acceptance criteria

- [ ] `mix compile` inside `apps/gibbering_engine/` passes with no Ecto/Phoenix in the dep tree
- [ ] `mix test` inside `apps/gibbering_engine/` passes
- [ ] `mix test` from umbrella root passes (remaining apps compile with updated module refs)
- [ ] `mix precommit` from umbrella root passes
- [ ] No `Ecto` or `Phoenix` module references appear in `apps/gibbering_engine/lib/`
