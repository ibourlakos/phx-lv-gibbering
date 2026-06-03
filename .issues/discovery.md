# Discovery Issues

Discovery issues capture open questions, design unknowns, and epic-scale work that surfaces from brainstorming. They are not immediately actionable — they need scoping before they become concrete tasks.

---

## #2 · Wizard first unique mechanic: ranged attack or AOE spell

**Status:** open  
**Opened:** 2026-06-04  
**Priority:** medium  

From brainstorming `03-the-proving-grounds.md`. Wizard currently has identical mechanics to Warrior (shorter move range only). Two candidate first mechanics:

- **Ranged attack** — no adjacent-tile requirement; fires across the grid. Simpler to implement, validates ranged targeting logic.
- **AOE spell** — SVG circle overlay covering multiple tiles. More visually impressive; validates area-effect targeting and multi-target damage.

**Acceptance criteria**
- [ ] Decision recorded here and in the relevant brainstorming doc
- [ ] Chosen mechanic implemented and exercised in the Proving Grounds scenario
- [ ] Ruleset module handles the new targeting type cleanly

---

## #3 · Save/load: before or after Ruleset behaviour split

**Status:** open  
**Opened:** 2026-06-04  
**Priority:** medium  

From brainstorming `03-the-proving-grounds.md`. Campaign state is not persisted back to Postgres during a session — a server restart loses all mid-game positions. Open question: do we wire up persistence before splitting out the `Gibbering.Ruleset` behaviour, or after?

- **Before:** simpler — no abstraction boundary to cross yet; concrete DnD5e state is easy to serialise.
- **After:** cleaner — persistence speaks to the generic engine layer, not a ruleset-specific shape.

**Acceptance criteria**
- [ ] Decision recorded here with rationale
- [ ] Chosen order reflected in the implementation roadmap / next brainstorm
- [ ] Mid-game state survives a `docker compose restart app`

---

## #5 · Isometric rendering overhaul (2:1 dimetric)

**Status:** closed  
**Opened:** 2026-06-04  
**Closed:** 2026-06-04  
**Priority:** high  

Switch the SVG rendering pipeline from top-down square tiles to 2:1 dimetric isometric diamond tiles, matching the Don't Starve Together camera angle. Full spec in `04-dst-aesthetic-sprites.md`.

Covers:
- Replace `<rect>` tile elements with `<polygon>` diamonds using the `(x−y, x+y)` projection
- Add tile decoration layer (dead tree, rock cluster, bones) between tile and entity layers
- Add `decoration` field to `GridTile`
- Depth-sort entity render pass by `y * map_width + x`
- Add shadow `<ellipse>` beneath each entity
- Add `sprite` field to `Entity` struct (atom key; `nil` falls back to colored rect)
- SVG character sprites for Warrior, Wizard, The Rock (inline SVG paths, no raster files)
- Update Proving Grounds seed with decorated tiles

**Acceptance criteria**
- [ ] Tile grid renders as diamonds with correct adjacency and no gaps
- [ ] Entities depth-sort correctly (entities closer to the bottom of screen render on top)
- [ ] All existing click interactions work unchanged (select, move, attack, end turn)
- [ ] Warrior, Wizard, The Rock have distinct SVG sprite shapes (not rectangles)
- [ ] At least 2 decoration types appear on the Proving Grounds map
- [ ] Multiplayer sync still works (two tabs stay in sync)

---

## #6 · Raster sprite asset pipeline

**Status:** open  
**Opened:** 2026-06-04  
**Priority:** low  

Design and wire the path for raster sprite files so that when we're ready to add hand-drawn or pixel art sprites we don't have to retrofit the rendering layer. SVG sprites from #5 stay as the v1 implementation; this issue is about the load path only.

Covers:
- Define `priv/static/images/sprites/` as the canonical sprite directory
- Update `GibberingWeb.Endpoint` static config if needed
- Document the legal gate in `docs/legal.md`: every file added to `sprites/` must have its license recorded before the commit
- Evaluate CC0 candidates (Kenney "Tiny Dungeon", LPC) and record findings in `docs/legal.md`
- Render path: `<image href="/images/sprites/<key>.png">` in the entity SVG group, gated on `entity.sprite != nil` and file existence

**Acceptance criteria**
- [ ] A placeholder sprite PNG loads correctly in the SVG viewport via the static path
- [ ] `docs/legal.md` has a "Sprite assets" section covering evaluation of at least two CC0 candidates
- [ ] At least one raster sprite replaces one SVG-drawn sprite from #5 in the Proving Grounds

---

## #4 · Fog of war vs sprites: which comes first

**Status:** closed  
**Opened:** 2026-06-04  
**Closed:** 2026-06-04  
**Priority:** low  

From brainstorming `03-the-proving-grounds.md`. Entities are still colored rectangles with letter initials. Two motivating next steps:

- **Sprites first** — more motivating to play with; unblocks art pipeline and visual identity.
- **Fog of war first** — more architecturally interesting; requires per-player visibility state and selective SVG rendering.

**Decision:** Sprites first, paired with a full visual overhaul to the DST (Don't Starve Together) aesthetic. See `04-dst-aesthetic-sprites.md`. The visual overhaul (isometric rendering + SVG sprites) is tracked in #5 and #6.

**Acceptance criteria**
- [x] Decision recorded here with rationale
- [ ] Chosen feature implemented and playable in the Proving Grounds scenario
