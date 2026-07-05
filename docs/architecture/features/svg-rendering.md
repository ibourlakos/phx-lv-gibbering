# SVG Rendering Pipeline

## Projection

The game uses **2:1 dimetric isometric** projection (the same camera angle as Don't Starve Together). All coordinate math lives in `GibberingEngine.Projection.Isometric` as pure functions.

Grid `(x, y)` → screen `(sx, sy)` with origin offset:
```
sx = (x - y) * (tile_w / 2) + origin_x
sy = (x + y) * (tile_h / 2) + origin_y
```
where `tile_w = 64`, `tile_h = 32`, `origin_x = map_height * 32 + 32`, `origin_y = 64`.

Each tile is a diamond `<polygon>` (4 points: top / right / bottom / left). Entity sprites are upright `<g>` elements that do **not** rotate with the grid — they face the camera, billboard-style.

## Layer stack (bottom to top)

| # | Layer | SVG element | Notes |
|---|---|---|---|
| 1 | Ground tiles | `<polygon>` | Diamond per cell; DST dark palette |
| 2 | Tile decorations | `<g>` (depth-sorted) | Trees, rocks, bones; inline SVG paths |
| 3 | Move overlay | `<polygon phx-click="move">` | Blue diamond; shown when entity selected |
| 4 | Entities | `<g>` (depth-sorted by x+y) | Inline SVG sprite + HP bar |
| 5 | Selection/target highlight | inside entity `<g>` | Diamond ring; always on top of sprite |

**Depth sort:** entities and decorations are sorted ascending by `x + y` before rendering. Lower `x + y` = further from camera = drawn first = appears behind.

## Sprite strategy

All entity sprites render through one pipeline (unified in #180 — the old per-`"{race}_{class}"` hardcoded heex clauses are gone):

1. `GibberingTalesWeb.Components.EntitySprites.entity_sprite/1` (extracted from `GameLive` per the long-parked #19 TODO) is the single call site, reused by both the game board and the lobby card preview.
2. It resolves `entity.sprite` → `archetype` + `silhouette` via `GibberingEngine.ActorAppearance` (content-agnostic: archetype/silhouette resolution, socket offsets, per-facing layer order, facing/flip, size-category scaling — no knowledge of any specific game's art).
3. `ActorAppearance.render_body/4` composes the resolved layers by calling an **injected renderer callback** per layer — the actual SVG markup is game-specific content and lives outside the engine (see [engine-decomposition.md](../engine-decomposition.md)).
4. `GibberingTales.Catalogue.TemplateStore` is that renderer: it compiles `.svg.eex` files from `apps/gibbering_tales/priv/appearance_templates/<style>/<archetype>/<silhouette>/<facing>/<layer>.svg.eex` into functions at build time, falling back to the `"dst"` style for any (archetype, silhouette, facing, layer) combination a style hasn't authored.

Current sprite keys follow the `"{race}_{class}"` convention for player characters (e.g. `"elf_wizard"`, `"gnome_rogue"`); NPCs and objects use freeform keys (`"rock"`). Within `:biped_upright`, a `silhouette` (`:humanoid`, `:goblinoid`, `:undead_gaunt`, `:giant`) gives distinct body-plan proportions to different sprite keys instead of one generic recolored shape.

Two styles exist today: `"dst"` (the original ink/outline look) and `"carbot"` (bold outlines, chibi big-head proportions — an original, inspired-by take, not a trace of any specific artwork). Style selection is DB-driven (`Catalogue.Style`/`Catalogue.appearances_for_style/1`); in dev, `GameLive`'s `?style=<slug>` query param overrides `Catalogue.default_style_slug/0` for local preview.

No raster files — no asset pipeline, no LFS, no license risk at this stage. The entity's `sprite` field is the hook point for future raster sprites (`<image href="/images/sprites/<key>.png">`).

Key CSS: `image-rendering: pixelated` on the root `<svg>` for crisp scaling when raster sprites arrive.

## Why SVG diffs are cheap

When an entity moves, LiveView sends only the changed attributes (`transform` on one `<g>`), not the full map. A 50×50 map move is a few bytes over the wire.
