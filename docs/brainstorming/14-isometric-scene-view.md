# 14 — Isometric Scene View & Full-Viewport Rendering

## Context

The current game scene renders into a constrained area alongside other page chrome.
This brainstorm explores moving to a full-viewport game canvas where the SVG scene
fills 100% of the browser window and all other UI (abilities, HP, menus, turn order)
floats as lightweight overlay layers on top of it.

The visual and zoom reference is *Don't Starve Together*: moderately zoomed out,
readable grid density, strong silhouettes, top-down-ish isometric angle — not
hyper-zoomed tactical (like XCOM) and not so far out that individual entities lose
legibility. Entities should read clearly at a glance.

---

## Full-Viewport Scene

### Layout Model
- The game SVG becomes the document root — `position: fixed`, `width: 100vw`, `height: 100vh`, `z-index: 0`
- No page scrollbar; the scene itself handles pan
- All other elements are `position: absolute/fixed` with higher z-index, pointer-events scoped to their hit areas only
- The LiveView socket still drives all state; this is purely a rendering/layout change

### Viewport & Coordinate System
- The SVG `viewBox` defines the visible world slice; panning shifts the viewBox origin
- Zooming scales the viewBox (shrink viewBox = zoom in, expand = zoom out)
- Target zoom range: roughly 2–4 tiles visible across a "standard" laptop screen width feels DST-like — needs playtesting to calibrate
- Tile size in SVG units: currently unknown — establish a base tile size constant and work relative to it

### Pan & Zoom
- Pan: click-and-drag on the background (no entity under cursor), or WASD/arrow keys
- Zoom: scroll wheel, or pinch on touch
- Clamp pan to map bounds (with a small overscroll margin so the edge doesn't feel hard)
- Zoom min/max bounds: don't allow zooming so far out that entities become unreadable, don't allow so far in that the grid feels claustrophobic
- Camera can optionally center on the active PC at turn start (opt-in setting)

---

## Isometric Rendering Improvements

### Projection
- Current projection angle: confirm or establish — DST uses a mild isometric angle, closer to top-down than classic 2:1 iso
- Tile shape: diamond (standard iso) vs. rectangular top-down — DST uses diamond-ish but squashed; worth exploring squash ratio
- Depth sorting: entities further "up" the screen (lower Y in world space) render behind entities further "down" — painter's algorithm on the SVG element order

### Tile & Grid Aesthetics
- Grid lines: subtle, low-contrast, possibly only visible at closer zoom levels (fade out as you zoom out)
- Tile fill: base terrain texture as SVG pattern or flat color blocks with a border treatment
- Elevation indication: drop shadow or outline offset on entities sitting "on top of" a tile

### Entity Rendering (DST-Inspired)
- Strong, readable silhouettes — thick outlines relative to entity size
- Entities slightly taller than a tile to give vertical presence
- HP bar and status icons are small and hug the entity, not a separate UI panel
- Selected entity gets a highlight ring (not a bounding box)
- Hover state: subtle brightness lift, cursor changes

---

## Overlay UI Layer System

The goal is that no UI element occludes gameplay unnecessarily.
All panels should be collapsible, minimal, and positioned at the screen periphery.

### Layer Stack (z-index order, low to high)
1. **Scene SVG** — the map, entities, effects
2. **Scene overlays** — selection rings, movement range highlights, AoE previews (rendered inside the SVG, not HTML)
3. **HUD layer** — HP/status of visible entities (thin bars attached to entity positions, could be SVG foreignObject or positioned HTML)
4. **Action bar** — ability/item bar, fixed bottom-center, translucent background
5. **Turn order strip** — fixed top or side, compact portrait/icon strip
6. **Info panel** — right or left edge, slides in on entity select, slides out when deselected
7. **DM panel** — similar to info panel but DM-only, opposite edge
8. **System overlays** — pause banner, end-of-session screen, connection lost notice (full-screen, highest z)

### Design Principles for Overlay Panels
- Translucent/frosted backgrounds (CSS `backdrop-filter: blur` or equivalent SVG treatment) — panels shouldn't hard-occlude the map
- Collapsed by default except action bar and turn order strip
- No modal dialogs during combat if avoidable — prefer inline confirmations or hold-to-confirm
- Panels should not reflow the page; everything is absolutely positioned

---

## Art Direction (DST-Inspired)

### Overall Aesthetic
- Hand-drawn feel: slightly rough, sketchy outlines rather than clean vector strokes
- Gothic/whimsical tone — dark fairy-tale, not horror, not bright fantasy
- Strong black (or very dark) outlines on all entities and terrain elements; line weight varies slightly for depth
- Muted, desaturated base palette with selective pops of color (fire, magic effects, UI accents)
- Ground tiles: simple, flat-ish with low-contrast texture — the scene's visual weight lives in the entities, not the floor

### Entities & Characters
- Slightly exaggerated proportions — large heads, expressive silhouettes, readable at small sizes
- Minimal internal detail; read from silhouette first, secondary details second
- Idle animation: subtle (breathing bob, cloak sway) — keeps the scene alive without noise
- Status effects get a distinctive visual treatment (color tint, particle, icon) that reads clearly over the sketchy art

### Environment & Lighting
- Dark vignette at viewport edges — the scene feels like it exists in a pool of light, not a white canvas
- Light sources (torches, spells) cast a warm local glow via SVG radial gradients or filter effects
- Shadows: flat drop shadows on entities to ground them on the tile; no dynamic ray casting
- Night/underground maps lean heavily dark; outdoor/day maps use a cooler ambient

### UI & Typography
- Panel backgrounds: dark, slightly textured (parchment or aged wood feel) — consistent with the gothic tone
- Font: serif or slab-serif for headers, legible at small sizes; no clean sans-serif tech look
- Icons: hand-drawn style consistent with entity art; avoid flat modern icon sets
- Color coding (HP, action type, damage type) uses the same muted palette — no neon

### Implementation Notes
- SVG filters (`feTurbulence`, `feDisplacementMap`) can approximate a hand-drawn texture pass on outlines without requiring hand-drawn assets for every element
- Palette should be defined as a small set of CSS/SVG variables so it can be swapped or themed at the campaign level (e.g., a desert campaign has a warmer palette)
- Art style definition and a reference tile/entity should be produced before committing to any large content pass (gates brainstorm #11 content work)

---

## Technical Considerations

### SVG vs. HTML Overlay Split
- Stick to SVG for anything that needs to move with the world coordinate system (entity labels, range rings, AoE previews)
- HTML for anything anchored to the screen (action bar, turn order, system panels)
- Avoid mixing SVG foreignObject too heavily — it complicates event handling

### LiveView Integration
- Phx push patches drive entity position / state changes; the SVG layer morphs in place
- Pan/zoom state is purely client-side (a JS hook); it does not round-trip to the server
- Viewport resize events update the viewBox via the same JS hook

### Performance Concerns
- Large maps: only render tiles within (or near) the current viewBox — tile culling
- Entity count: SVG handles hundreds of elements fine; above ~500 visible nodes consider canvas fallback (defer)
- Animation: CSS transitions on entity SVG elements for smooth movement, not JS animation loops

---

## Open Questions

- What is the current tile size constant and how many tiles are on a "standard" map? Need this to calibrate zoom levels.
- Do we commit to diamond isometric or allow map-level projection config (top-down vs. iso)?
- Should pan/zoom state be stored in the URL (shareable viewport) or purely ephemeral client state?
- How do we handle mobile / touch — is it in scope at all, or desktop-only for now?
- Action bar: ability icons are currently placeholder — does this brainstorm depend on a content pass first, or can we build the layout with stubs?
- Should the turn order strip show portraits (requires art) or abstract colored tokens?
- Accessibility: keyboard-only navigation of the overlay panels — defer or baseline requirement?
- Do we want a minimap? DST has one — useful for large maps, non-trivial to implement cleanly in SVG.

---

## Cross-References

- Brainstorm #11 — game content workflow (entity appearance components feed into rendering)
- Brainstorm #12 — player/DM experience (overlay panels for DM controls tie into this layout model)
