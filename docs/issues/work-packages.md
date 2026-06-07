# Work Packages
_Temporary planning doc — not an issue file. Delete when packages are actioned._

Generated: 2026-06-05 · Last updated: 2026-06-07 (WP-D ✓ complete except #92 discovery; WP-G ✓ complete; WP-F: closed through #104; WP-H ✓ complete)

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
_#54–#57, #90–#95 all closed as of 2026-06-06. One discovery straggler remains._

| # | Title | Priority |
|---|---|---|
| [#92](092-spectator-role-discovery.md) | Spectator role — membership and session view (discovery) | low |

---

## WP-G — Integration Test Coverage ✓ complete
_#76, #77, #78 all closed as of 2026-06-06._

---

## WP-E — Admin App ✓ complete
_All 8 issues closed as of 2026-06-07: #64, #65, #66, #67, #68, #69, #74, #75._

---

## WP-F — Rendering & Frontend
_SVG pipeline bugs, viewport architecture, and art direction. Expanded with discoveries from brainstorm #14._
_Closed: #97, #98, #13, #99, #81, #103, #10, #102._

| # | Title | Priority |
|---|---|---|
| [#25](025-ruleset-ui-declaration.md) | Ruleset UI declaration: action buttons + stat panels (discovery) | medium |
| [#26](026-fog-of-war-ownership.md) | Fog-of-war ownership: ruleset or engine? (discovery) | medium |
| [#34](034-active-effect-visual-and-animation.md) | Active effect visual representation and animation (discovery) | medium |
| [#82](082-z-axis-elevation-projection-and-los.md) | Z-axis elevation — projection, depth sorting, and LOS (discovery) | low |
| [#83](083-volumetric-spell-effect-rendering.md) | Volumetric spell effect rendering (discovery) | low |
| [#84](084-lod-sprite-detail-levels-for-zoom.md) | LOD sprite detail levels for zoom (discovery) | low |
| [#101](101-dm-top-down-projection-mode.md) | DM top-down projection mode (discovery) | low |
| [#21](021-dice-roll-cycling-faces.md) | Dice roll cycling faces | low |
| [#27](027-tile-decoration-storage.md) | Tile decoration storage (discovery) | low |
| [#28](028-multi-tile-entities.md) | Multi-tile entity footprints (discovery) | low |

Sequencing: #100 first (compositing pipeline discovery — unblocks SVG fragment wiring). #25/#26/#34 are independent discovery items. #84 (LOD) after zoom is stable. #83/#82/#101 are long-horizon discoveries.

---

## WP-H — Game Content ✓ complete
_#88 (taxonomy) and #89 (initial population: 9 races, 12 classes, 12 monsters) both closed 2026-06-07._

---

## WP-I — Monitoring *(new)*
_Observability stack. Independent of all other WPs; can be done any time._

| # | Title | Priority |
|---|---|---|
| [#96](096-promex-prometheus-grafana-stack.md) | PromEx + Prometheus + Grafana monitoring stack | low |

#96 is the infrastructure layer. #68 and #69 (in WP-E) are the in-app admin panels; they are complementary, not alternatives.

---

## Cross-cutting Threads
_No strict phase placement. Resolve in parallel or as needed._

| # | Title | Notes |
|---|---|---|
| [#16](016-lpc-sprite-license-risk.md) | LPC sprite copyleft risk | Legal — blocks #6 and #89 |
| [#6](006-raster-sprite-pipeline.md) | Raster sprite asset pipeline | Blocked on #16 |
| [#19](019-lobby-edits-stale-gameserver.md) | Lobby edits don't propagate to running GameServer | Bug — no WP home yet |
| [#32](032-dm-override-event-schema.md) | DM override event schema and god-mode mechanics | Discovery — prerequisite for #95 |
| [#33](033-templates-governance-model.md) | Templates governance model | Discovery |
| [#63](063-playwright-smoke-tests.md) | Playwright smoke tests + smoke Docker env | Ops |
| [#80](080-inventory-and-loot-container-system.md) | Inventory and loot container system | Discovery — depends on #79 + WP-C |
| [#85](085-content-creation-tools-design.md) | Content creation tools — design and scope | Discovery — spans WP-E + future UGC |
| [#92](092-spectator-role-discovery.md) | Spectator role (discovery) | Discovery — gates spectator impl in WP-D |

---

## Suggested sequencing

```
WP-A ✓  →  WP-B ✓  →  WP-C ✓  →  WP-D  →  WP-G (#78)
                       ↘  WP-E  (parallel with WP-D)
                       ↘  WP-F: #97+#98 first, then #81/#99, then remaining discoveries
                       ↘  WP-H: #88 discovery, then #89 (needs #16 clear)
                          WP-I: #96 any time
                          WP-G: #76 and #77 free-floating — can start now
```

WP-A, WP-B, WP-C, WP-D, and WP-G are complete. **Current focus: WP-H #88 (content taxonomy discovery, medium) → #89 (content population). WP-E stragglers (#69, #68, #74) and WP-F discoveries (#25, #26, #34) can run in parallel. WP-I (#96) is fully independent.**
