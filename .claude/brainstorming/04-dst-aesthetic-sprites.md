# Don't Starve Together Aesthetic — Visual Overhaul & Sprite Pipeline
### Prototype v1 Planning

**Date:** 2026-06-04  
**Status:** Brainstorm / pre-implementation

---

## The Target Aesthetic

Don't Starve Together's visual language is a precise set of choices we can translate without needing their art:

| DST trait | What it does | Our translation |
|---|---|---|
| Tim Burton / Edward Gorey ink-style | Thick black outlines, spindly shapes, hand-drawn feel | Thick `stroke` on all SVG shapes; sprite silhouettes over sharp fills |
| Desaturated palette + pops | Muted grays/browns for world; saturated for characters and UI | Ground tiles stay dark; hero sprites get one signature color |
| Slight camera elevation | Objects "stand up" from the ground plane | 2:1 dimetric isometric projection (see below) |
| Billboard characters | Sprites face the camera regardless of move direction | Upright `<image>` elements on top of a tilted ground plane |
| Painted-on shadows | Shadow blob under every standing object | Static dark ellipse SVG element beneath each entity sprite |
| Cluttered world | Trees, rocks, bones scattered on tiles | Decoration layer between tile and entity layers |

---

## Projection Decision: 2:1 Dimetric Isometric

We are moving from **top-down 90°** to **2:1 dimetric isometric** (also called "RPG isometric"):

```
Top-down (now)         2:1 Dimetric (v1)

 □ □ □ □               ◇   ◇   ◇
 □ □ □ □             ◇   ◇   ◇   ◇
 □ □ □ □               ◇   ◇   ◇
```

**Why 2:1 dimetric over strict 45° isometric:**
- Tile width = 2× tile height — this matches DST's ground angle almost exactly
- Grid cells are diamond polygons; pixel art sprites for this ratio are standard (RPG Maker, Stardew Valley, Diablo II all use it)
- Upright sprites don't need to be rotated — they stand perpendicular to screen, which is exactly what DST does
- SVG click events work natively on `<polygon>` hit areas

**No zoom requirement simplifies everything** — we fix the tile size and never scale the SVG viewport.

**Rotation:** 90° or 45° turns rotate the logical grid. Screen projection stays fixed. There is no camera — only the coordinate transform changes when we later add rotation.

---

## Projection Math

Let `tw = tile_width` (e.g. 64px), `th = tile_height = tw / 2` (32px).

```
# Logical grid (x, y) → screen (sx, sy):
sx = (x - y) * (tw / 2)
sy = (x + y) * (th / 2)

# Origin offset (so grid starts at centre-top of SVG, not top-left):
origin_x = map_height * (tw / 2)   # shift right so first column has room
origin_y = 0                        # or add padding
```

Each tile is a diamond `<polygon>` with 4 points:
```
top:    (sx,          sy)
right:  (sx + tw/2,   sy + th/2)
bottom: (sx,          sy + th)
left:   (sx - tw/2,   sy + th/2)
```

Entity sprite placement (upright, centered on tile):
```
image_x = sx - tw / 2
image_y = sy - tw + th / 2    # sprite extends upward from tile center
image_w = tw
image_h = tw                  # square sprite; taller sprites use tw * 1.5
```

Depth sort before rendering entities (painter's algorithm):
```elixir
sorted = Enum.sort_by(entities, fn {_id, e} -> e.y * map_width + e.x end)
```

---

## SVG Layer Stack (revised)

| # | Layer | SVG element | Notes |
|---|---|---|---|
| 1 | Ground tiles | `<polygon>` | Diamond, filled, stroked |
| 2 | Tile decorations | `<g>` per tile | Trees, rocks, bones — static clutter |
| 3 | Shadows | `<ellipse>` | Dark semi-transparent blob under each entity |
| 4 | Move overlay | `<polygon phx-click="move">` | Semi-transparent blue diamonds |
| 5 | Entities | `<g>` depth-sorted | Sprite `<image>` or SVG paths + HP bar |
| 6 | Attack/select highlight | inside entity `<g>` | Stays on top — same as now |

---

## Sprite Strategy: SVG-First for v1

For prototype v1 we draw sprites as **inline SVG paths**, not raster images. This means:

- Zero asset pipeline — no files to commit, no LFS needed yet
- Can iterate shape/color instantly  
- Fully owned — no license risk
- Matches DST's inky aesthetic naturally (SVG strokes = ink lines)

### Character sprite conventions

All sprites are drawn in a normalized `viewBox="0 0 64 64"`, placed at computed `image_x/image_y` via `<g transform="translate(x, y)">`:

```
Warrior:  humanoid silhouette, helmet, broad shoulders
          fill: #4a6fa5, stroke: #1a1a2e, stroke-width: 2
          
Wizard:   pointed hat, robes, thinner frame
          fill: #7b5ea7, stroke: #1a1a2e, stroke-width: 2
          
Goblin:   shorter, hunched, large ears
          fill: #5a7a3a, stroke: #1a1a2e, stroke-width: 2
```

### Tile variant conventions

| Texture | Fill | Stroke | Notes |
|---|---|---|---|
| grass | `#3d6b45` | `#2a4d30` | Dark muted green |
| stone | `#5a5a5a` | `#383838` | Charcoal |
| rubble | `#7a6248` | `#4d3d2c` | Warm brown |
| water | `#2d4a6b` | `#1a2d45` | Deep blue-gray |
| sand | `#a08c5a` | `#7a6a3a` | Dull ochre |

### Clutter decorations (static, no interaction)

Placed at tile paint time if `tile.decoration` is set:

- `:dead_tree` — thin trunk + bare branches, ink-style
- `:rock` — irregular polygon cluster
- `:bones` — small crosses + scatter shapes
- `:grass_tuft` — 3 thin triangles

---

## Entity struct changes

Add `sprite` field (atom key into a sprite registry):

```elixir
# Entity fields added:
sprite: :warrior | :wizard | :goblin | :rock | nil

# Tile fields added:
decoration: :dead_tree | :rock | :bones | :grass_tuft | nil
```

Rendering switches on `sprite` — if `nil`, falls back to the colored rectangle (current behavior, for safe migration).

---

## Click Handling with Isometric Tiles

SVG `<polygon>` elements handle hit testing automatically based on their actual diamond shape — no click math needed. The existing `phx-value-x` / `phx-value-y` pattern works unchanged. Each tile polygon carries its logical coordinates.

Move overlay polygons are generated identically to tile polygons, just filtered to `valid_moves`.

---

## Raster Sprite Path (Future)

When we're ready to add hand-drawn or pixel art sprites:

1. Drop files in `priv/static/images/sprites/` — filename convention `<sprite_key>.png`
2. Serve via Phoenix static endpoint (already configured)
3. `<image href="/images/sprites/warrior.png" ...>` in SVG — `image-rendering: pixelated` is already set on the root `<svg>`
4. **Legal gate**: every file added to `sprites/` must have its license recorded in `docs/legal.md` before the commit lands

CC0 candidates to evaluate later:
- Kenney.nl "Tiny Dungeon" tileset (CC0) — clean pixel art, may need recolouring to DST palette
- OpenGameArt `LPC` (Liberated Pixel Cup) characters — CC-BY-SA, check share-alike implications
- Hand-commissioned sprites — simplest legal path; full ownership

---

## Prototype v1 Scope

**In:**
- Isometric tile rendering (replace `<rect>` tiles with `<polygon>` diamonds)
- Depth-sorted entity rendering
- SVG character sprites for Warrior, Wizard, The Rock
- Shadow ellipse under each entity
- 2–3 tile decoration types (dead tree, rock cluster, bones)
- Entity struct `sprite` field; `GridTile` `decoration` field
- Updated Proving Grounds seed with some decorated tiles

**Out (deferred):**
- Raster sprite loading — design the path, don't wire it yet
- Fog of war — unchanged (still no fog)
- Tile rotation — the projection is fixed; 90°/45° board rotation is a future feature
- Animations — move is still instant; no tweening

---

## Open Questions

- Should tile decorations be stored in `GridTile` or as a separate decoration entity? (Entity approach is more flexible but heavier; tile field is simpler for non-interactive clutter.)
- How do we handle multi-tile entities (a 2×2 boss)? Sprite spans multiple diamonds — depth sort gets complicated. Defer or design the seam now?
- Do HP bars stay horizontal (screen-aligned) or rotate with the tile? Screen-aligned is more readable; DST uses screen-aligned UI elements.
- Should the shadow ellipse scale with entity size, or be a fixed size per tile?
