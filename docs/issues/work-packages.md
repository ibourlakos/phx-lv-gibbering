# Work Packages
_Temporary planning doc — not an issue file. Delete when packages are actioned._

Generated: 2026-06-05 · Last updated: 2026-06-07 (WP-D ✓ complete except #92 discovery; WP-G ✓ complete; WP-F: closed through #104; WP-H ✓ complete; WP-J added — polytope operationalization wave #107–#113)

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
| [#101](101-dm-top-down-projection-mode.md) | DM top-down projection mode (discovery) — **gated by WP-J #113** | low |
| [#21](021-dice-roll-cycling-faces.md) | Dice roll cycling faces | low |
| [#27](027-tile-decoration-storage.md) | Tile decoration storage (discovery) | low |
| [#28](028-multi-tile-entities.md) | Multi-tile entity footprints (discovery) | low |

Sequencing: #25/#26/#34 are the live medium-priority items. #84 (LOD) after zoom is stable. #83/#82 are long-horizon discoveries. **#101 (DM top-down projection) is gated by WP-J #113 (CQRS read model formalization) — do not start until #113 is closed.**

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

## WP-J — Architecture Operationalization *(active)*
_Making the polytope bounded-context architecture (docs/papers/polytope-architecture.md) actionable in the codebase. All issues are medium or low priority. Largely independent of WP-F, but #113 gates two downstream items — see note below._

Dependency chain:

```
#107 ✓ (namespace alignment) → #108 (EventBus port/adapter) → #111 (batch emission) → #113 (CQRS read model)
#107 ✓ → #112 (bounded context map doc)
#109 (compound bus enforcement) — independent
#110 (SceneServer single-writer) → #111
```

| # | Title | Priority | Depends on |
|---|---|---|---|
| ~~[#107](107-bounded-context-namespace-alignment.md)~~ | ~~Bounded context module namespace alignment~~ ✓ | medium | — |
| [#109](109-compound-bus-command-event-separation.md) | Compound bus: command/event separation — B=(C,E) enforcement | medium | — |
| [#110](110-sceneserver-single-writer-contract.md) | SceneServer single-writer contract | medium | — |
| [#108](108-eventbus-behaviour-port-adapters.md) | EventBus behaviour: port and adapters | medium | #107 ✓ |
| [#111](111-event-cascade-batch-emission.md) | Event cascade batch emission — Event Aggregator pattern | medium | #110, #108 |
| [#112](112-bounded-context-map-document.md) | Bounded context map document | low | #107 ✓ |
| [#113](113-cqrs-read-model-formalization.md) | CQRS read model formalization — explicit projections per adapter | low | #111 |

**Suggested WP-J sequencing:** Start #107, #109, and #110 in parallel (all independent). Once #107 lands, open #108. Once #108 and #110 land, open #111. #112 can follow #107 at any time. #113 closes the chain and is a prerequisite for two other items:

- **#113 gates #92** (spectator role — membership and session view; currently a discovery in WP-D cross-cutting thread): the read model must be formalized before the spectator adapter can be specified.
- **#113 gates #101** (DM top-down projection mode; currently in WP-F): the projection mode is itself a read model; implement only after #113 defines the pattern.

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
| [#92](092-spectator-role-discovery.md) | Spectator role (discovery) | Discovery — gates spectator impl in WP-D; **gated by WP-J #113** |

---

## Suggested sequencing

```
WP-A ✓  →  WP-B ✓  →  WP-C ✓  →  WP-D ✓  →  WP-G ✓
                       ↘  WP-E ✓  (parallel with WP-D)
                       ↘  WP-F: #25/#26/#34 active; #101 gated by WP-J #113
                       ↘  WP-H ✓
                          WP-I: #96 any time (independent)
                          WP-J: #107/#109/#110 in parallel →
                                #108 (after #107), #111 (after #108+#110) →
                                #113 → unblocks WP-F #101 and cross-cutting #92
                                #112 (after #107, low priority, any time)
```

**Current focus:** WP-F medium items (#25, #26, #34) are the live work. WP-J can begin immediately and runs in parallel — start with #107, #109, #110 (all independent of each other and of WP-F). WP-I (#96) is fully independent. **Do not begin WP-F #101 or cross-cutting #92 until WP-J #113 is closed.**
