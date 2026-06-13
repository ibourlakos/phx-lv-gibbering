# Work Packages
_Temporary planning doc — not an issue file. Delete when packages are actioned._

Generated: 2026-06-05 · Last updated: 2026-06-13 (WP-J ✓ complete; WP-D ✓ fully complete; WP-F discoveries #25/#26/#34/#27/#101 closed; WP-K/WP-L/WP-M added from derived implementation issues; WP-N added from BS-17 Phase 1 decisions)

---

## WP-A — Infrastructure & Data Plumbing ✓ (1 straggler)
_All high/medium issues closed. One low-priority item remains._

| # | Title | Priority |
|---|---|---|
| [#24](024-grid-data-jsonb.md) | Consolidate `grid_tiles` rows into JSONB column | low |

---

## WP-B — Core Engine Architecture ✓ (1 straggler)
_All high/medium issues closed. One low-priority item remains._

| # | Title | Priority |
|---|---|---|
| [#15](015-stats-map-tradeoff.md) | Document `stats: map()` tradeoffs for entity stats | low |

---

## WP-C — Rules Engine ✓ complete
_All 13 issues closed as of 2026-06-06._

---

## WP-D — Campaign & Character Lifecycle + DM Session Toolset ✓ complete
_#54–#57, #90–#95, #92 all closed. Spectator implementation extracted to WP-K._

---

## WP-E — Admin App ✓ complete
_All 8 issues closed as of 2026-06-07: #64, #65, #66, #67, #68, #69, #74, #75._

---

## WP-F — Rendering & Frontend *(active)*
_SVG pipeline, art direction, rendering polish. Discoveries #25/#26/#34/#27/#101/#82/#83 are all closed or deferred. Remaining open work:_

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#125](125-tile-decoration-field-and-rendering.md) | Tile decoration field and rendering | low | — |
| [#21](021-dice-roll-cycling-faces.md) | Dice roll cycling faces | low | — |
| [#84](084-lod-sprite-detail-levels-for-zoom.md) | LOD sprite detail levels for zoom | low | — |

Deferred items still in scope when relevant: #82 (Z-axis elevation), #83 (volumetric spell effects), #28 (multi-tile entity footprints).

**Sequencing:** #125 is the lead item (data model change + rendering pipeline; no dependencies). #21 and #84 are independent polish items. #82/#83/#28 remain deferred — do not start until a brainstorm specifically scopes them.

---

## WP-G — Integration Test Coverage ✓ complete
_#76, #77, #78 all closed as of 2026-06-06._

---

## WP-H — Game Content ✓ complete
_#88 and #89 both closed 2026-06-07._

---

## WP-I — Monitoring *(independent)*
_Observability stack. Independent of all other WPs; can be done any time._

| # | Title | Priority |
|---|---|---|
| [#96](096-promex-prometheus-grafana-stack.md) | PromEx + Prometheus + Grafana monitoring stack | low |

---

## WP-J — Architecture Operationalization ✓ complete
_#107, #108, #109, #110, #111, #112, #113 all closed as of 2026-06-13. Unblocked WP-K and WP-L._

---

## WP-K — Spectator Implementation *(new)*
_Derived from closed discovery #92. Sequence: data layer → presentation._

Dependency chain:

```
#121 (membership model: DB migration, auth) → #122 (LiveView session view)
```

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#121](121-spectator-membership-model.md) | Campaign membership: spectator role and invite flow | low | — |
| [#122](122-spectator-session-view.md) | Spectator session view: shared GameLive mount, full-map default, PC-perspective toggle | low | #121 |

**Sequencing:** #121 first — adds the `:spectator` enum value, `invited_by_user_id` FK, and extends the invite token mechanism. #122 second — wires spectator detection into `GameLive`, full-map render, PC-perspective toggle, spectator count HUD.

---

## WP-L — DM Projection & Top-Down Viewport *(new)*
_Derived from closed discovery #101. Sequence: rendering infrastructure → DM UI._

Dependency chain:

```
#123 (Projection behaviour: extract Isometric, implement TopDown) → #124 (DM top-down viewport)
```

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#123](123-projection-behaviour-modules.md) | `Projection` behaviour: Isometric + TopDown modules, renderer audit | low | — |
| [#124](124-dm-top-down-viewport.md) | DM top-down viewport: toggle, entity circles, grid labels, hover tooltip | low | #123 |

**Sequencing:** #123 first — defines the `Gibbering.Projection` behaviour, extracts existing isometric math into `Projection.Isometric`, implements `Projection.TopDown`, and threads the projection parameter through the render pipeline. #124 second — adds the DM toggle, switches the scene SVG to use `Projection.TopDown`, and adds entity circles, grid labels, and hover tooltip.

---

## WP-M — Inventory & Loot System *(new)*
_Derived from closed discovery #80. Sequence: data model → event engine + modifier integration._

Dependency chain:

```
#126 (data model: schema, JSONB fields, seeds) → #127 (event loop: SceneServer handlers + LiveView panel)
                                               → #128 (collect_modifiers: `:equipped_items` source)
```

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#126](126-inventory-and-container-data-model.md) | Inventory and container data model | low | — |
| [#127](127-item-pickup-event-loop.md) | Item pickup event loop | low | #126 |
| [#128](128-equipped-item-collect-modifiers-integration.md) | Equipped item `collect_modifiers` integration | low | #126 |

**Sequencing:** #126 first — adds `stats["object_subtype"]`, `stats["items"]`, and `stats["inventory"]` JSONB fields; seeds one loot container; updates the data model doc. #127 and #128 both depend on #126 and are independent of each other — do either order, or parallelise across sessions. #127 is the broader gameplay feature (event loop + LiveView panel); #128 is a focused rules-pipeline extension.

---

## WP-N — Campaign / Map Restructure Phase 1 *(new)*
_Derived from Brainstorm #17 settlement. Sequence: schema → movement model → rules engine._

Dependency chain:

```
#129 (maps table migration) → #130 (GridTile.movement JSONB) → #131 (entity movement stats + valid_moves)
```

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#129](129-maps-table-phase-1-migration.md) | Phase 1: introduce `maps` table | medium | — |
| [#130](130-grid-tile-movement-jsonb.md) | `GridTile.movement` JSONB — replace `walkable: boolean` | medium | #129 |
| [#131](131-entity-movement-stats-and-valid-moves.md) | Entity movement stats + `valid_moves` multi-mode deduction | medium | #130 |

**Sequencing:** #129 first — schema change prerequisite for everything downstream. #130 second — replaces `walkable` with multi-mode JSONB and updates `valid_moves` merge logic. #131 third — extends entity stats and wires action economy for mode-aware cost deduction.

**Note:** Phase 2 (scenes/scene_templates tables) is deferred until #85 brainstorm. #129 is also a prerequisite for unparking #85.

---

## Cross-cutting Threads
_No strict phase placement. Resolve in parallel or as needed._

| # | Title | Notes |
|---|---|---|
| [#16](016-lpc-sprite-license-risk.md) | LPC sprite copyleft risk | Legal — blocks #6 |
| [#6](006-raster-sprite-pipeline.md) | Raster sprite asset pipeline | Blocked on #16 |
| [#19](019-lobby-edits-stale-gameserver.md) | Lobby edits don't propagate to running GameServer | Bug — no WP home yet |
| [#32](032-dm-override-event-schema.md) | DM override event schema and god-mode mechanics | Discovery — deferred; revisit when DM intervention scope expands |
| [#33](033-templates-governance-model.md) | Templates governance model | Discovery — deferred |
| [#63](063-playwright-smoke-tests.md) | Playwright smoke tests + smoke Docker env | Ops — deferred |
| [#85](085-content-creation-tools-design.md) | Content creation tools — design and scope | Discovery — deferred |
| [#120](120-items-data-population.md) | Items data module population | Deferred — blocked on content pipeline decisions |

---

## Suggested sequencing

```
WP-A ✓  →  WP-B ✓  →  WP-C ✓  →  WP-D ✓  →  WP-G ✓
                       ↘  WP-E ✓  (parallel with WP-D)
                       ↘  WP-H ✓
                       ↘  WP-J ✓  →  unblocked WP-K and WP-L
                          WP-F: #125 lead, then #21 and #84 (independent polish)
                          WP-I: #96 any time (independent)

Active now:
  WP-F:  #125 → (#21, #84)         — rendering + decoration, all independent
  WP-K:  #121 → #122               — spectator membership model first, then session view
  WP-L:  #123 → #124               — Projection behaviour first, then DM top-down viewport
  WP-M:  #126 → (#127, #128)       — inventory data model first, then event loop + modifier wiring
  WP-N:  #129 → #130 → #131        — maps table, then movement JSONB, then entity stats + valid_moves
```

**No inter-package dependencies exist between WP-F, WP-K, WP-L, WP-M, and WP-N.** All five can run in any order, or interleaved issue by issue. Within each package the internal chain must be respected (data layer before presentation). WP-N is a prerequisite for unparking #85 (content creation tools).
