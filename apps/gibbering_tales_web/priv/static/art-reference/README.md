# Art Direction Reference — Gibbering Engine

> **Status:** Canonical spec as of #97 + #98 (closed 2026-06-07).  
> Superseded by whatever `docs/architecture.md` says after the rendering refactor.

---

## Tile size constant

| Constant | Value | Notes |
|---|---|---|
| `tile_w` | **64** SVG units | Diamond width; the x-axis step in IsoProjection |
| `tile_h` | **32** SVG units | Diamond height = `tile_w / 2`; enforces the 2:1 ratio |
| `sprite_box` | **64 × 64** SVG units | Square bounding box for all entity sprites |
| `origin_y` | **64** SVG units | Top padding so row-0 sprites don't clip the SVG edge |

These constants are canonical. `GibberingWeb.IsoProjection` is the single source of truth in code.

---

## Outline technique

All shapes use **stroke=`#0a0a0a`** (near-black, not pure black — slightly warmer).

| Element | `stroke-width` | `stroke-linejoin` |
|---|---|---|
| Entity body / head | `3` | `round` |
| Tile grid lines | `1` | (default) |
| HP bar (none — rect, no outline) | — | — |
| Selection ring | `2.5` | (default — polygon) |
| Active-turn ring | `2`, `stroke-dasharray="4 3"` | — |

Closed paths only. Open strokes (`<line>`) are used only for internal detail lines (sword, visor) at `stroke-width="1–2"`.

---

## Texture pass

SVG filter `<feTurbulence>` over the base fill, composited with `feBlend mode="multiply"`:

```xml
<filter id="grass-texture">
  <feTurbulence type="fractalNoise"
                baseFrequency="0.9 0.7"
                numOctaves="3"
                seed="42"
                result="noise"/>
  <feColorMatrix type="matrix"
                 values="0 0 0 0 0.05
                         0 0 0 0 0.08
                         0 0 0 0 0.02
                         0 0 0 0.35 0"
                 in="noise" result="tinted-noise"/>
  <feBlend in="SourceGraphic" in2="tinted-noise" mode="multiply"/>
</filter>
```

Apply the filter to a second `<polygon>` stacked over the base fill polygon (same shape, no stroke, filter only). This avoids redrawing the stroke through the filter.

Different tile types use different `baseFrequency` and `seed`:
- Grass: `baseFrequency="0.9 0.7"`, seed 42
- Stone: `baseFrequency="0.6 0.5"`, seed 7
- Water: `baseFrequency="0.3 0.2"`, seed 13 (animated via `<animate>` when implemented)

---

## Entity proportion conventions

| Part | Dimensions | Position (within 64×64 box) |
|---|---|---|
| HP bar bg | 56 × 5 px | x=4, y=2 |
| HP bar fill | variable × 5 px | x=4, y=2 |
| Head (circle) | r=9 | cx=32, cy=22 |
| Body (rect) | 20 × 24 | x=22, y=30 |
| Feet / shadow ellipse | rx=10, ry=3 | cx=32, cy=58 |

The sprite's ground contact point is at **y≈58** within the 64×64 box. `IsoProjection.sprite_pos/2` offsets the box so this point aligns with the tile diamond's bottom center (`sy + tile_h`).

---

## Full-viewport layout model (#97)

### Z-layer stack

| z-index | Layer | Host | Notes |
|---|---|---|---|
| 0 | SVG game scene | `<svg position:fixed>` | Full viewport; `pointer-events:all` |
| 10 | World-anchored overlays | Inside SVG | Rings, move-highlights, HP bars |
| 20 | Action bar | Fixed HTML, bottom-centre | `pointer-events:none` container |
| 30 | Turn-order strip | Fixed HTML, top-centre | `pointer-events:none` container |
| 40 | Info / selection panel | Fixed HTML, bottom-right | Semi-transparent |
| 50 | DM controls panel | Fixed HTML, top-right | Collapsible |
| 100 | System overlays | Fixed HTML | Pause screen, broadcast banners, modals |

### HTML / SVG split boundary

**Inside SVG (world-anchored):** ground tiles, decorations, move overlays, entity sprites, entity HP bars, selection rings, target highlights, spell AOE overlays.

**HTML overlays (screen-anchored):** action bar, turn order strip, initiative panel, selected entity detail panel, DM controls, session lifecycle buttons, broadcast banners, whisper popups, pause overlay, modals.

### Pointer-event scoping

```css
/* All overlay containers pass clicks through to SVG below */
.overlay { pointer-events: none; }

/* Only interactive elements inside overlays capture clicks */
.overlay button,
.overlay input,
.overlay select { pointer-events: auto; }
```

The `<svg>` element itself gets `pointer-events: all` (default). This means unhandled clicks fall through the HTML overlay containers to the SVG world.

### Pan/zoom boundary

The SVG `viewBox` attribute is **client-side state only**. A `PanZoom` JS hook manipulates `viewBox` directly without any server round-trip. The server only knows game state (who is selected, turn order, entity positions) — not camera position. Server-pushed state updates re-render SVG content; the hook preserves the current `viewBox` after each LiveView patch.

### GameLive layout

GameLive uses a dedicated `game_root.html.heex` layout (no navbar, `body { margin:0; overflow:hidden }`) or `layout: false` in its `mount/3` options. Regular routes continue to use the standard root layout with the navbar.

### LiveView navigation

`push_navigate/2` and `redirect/2` cleanly tear down the GameLive socket. The full-viewport CSS (`overflow:hidden` on body) is scoped to the game layout — leaving `/game/:id` restores normal scroll behaviour for other routes.

---

## Follow-up issues

These were extracted from #97/#98 and created after settlement:

| Issue | Title |
|---|---|
| #99 | Multi-style appearance system — `style_id` keying |
| #100 | SVG fragment store and compositing pipeline |
| (new) | GameLive full-viewport layout refactor |
