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

Sprites are **inline SVG paths** defined as public function components in `GibberingTalesWeb.GameLive`, dispatched by `entity.sprite` (string key). Being public allows the lobby card preview to reuse them. Current sprite keys follow the `"{race}_{class}"` convention for player characters (e.g. `"elf_wizard"`, `"gnome_rogue"`); NPCs and objects use freeform keys (`"rock"`).

No raster files — no asset pipeline, no LFS, no license risk at this stage. The entity's `sprite` field is the hook point for future raster sprites (`<image href="/images/sprites/<key>.png">`).

> **TODO (see #19):** sprite components should be extracted to a dedicated `GibberingTalesWeb.Components.EntitySprites` module rather than living in a LiveView.

Key CSS: `image-rendering: pixelated` on the root `<svg>` for crisp scaling when raster sprites arrive.

## Why SVG diffs are cheap

When an entity moves, LiveView sends only the changed attributes (`transform` on one `<g>`), not the full map. A 50×50 map move is a few bytes over the wire.
