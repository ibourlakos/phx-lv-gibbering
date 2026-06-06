# Work Packages
_Temporary planning doc — not an issue file. Delete when packages are actioned._

Generated: 2026-06-05 · Last updated: 2026-06-06 (added WP-H, WP-I; expanded WP-D and WP-F from brainstorms #11–14)

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

## WP-D — Campaign & Character Lifecycle + DM Session Toolset
_WP-D now spans the full campaign lifecycle: backend schema through live DM session controls. #54→#55→#56 are still the strict foundation. New issues (#90–#95) build on top._

| # | Title | Priority |
|---|---|---|
| [#54](054-campaign-character-schema.md) | `CampaignCharacter` schema (template-to-instance bridge) | medium |
| [#55](055-bidirectional-campaign-joining.md) | Bidirectional campaign joining (player request + DM invite) | medium |
| [#56](056-character-template-merge-logic.md) | Character template → live entity merge logic | medium |
| [#57](057-dm-character-adjustment-ui.md) | DM character adjustment UI (campaign prep) | medium |
| [#90](090-player-campaign-overview-page.md) | Player campaign overview page | medium |
| [#91](091-campaign-invite-link-token.md) | Campaign invite link / shareable token mechanism | medium |
| [#93](093-dm-session-lifecycle-controls.md) | DM session lifecycle controls (start, pause, resume, end) | medium |
| [#94](094-dm-initiative-panel.md) | DM turn and initiative management panel | medium |
| [#95](095-dm-intervention-toolset.md) | DM intervention toolset (broadcast, whisper, condition/HP override) | medium |
| [#92](092-spectator-role-discovery.md) | Spectator role — membership and session view (discovery) | low |

Sequencing: #54 → #55 → #56 are strictly sequential. #57 is the prep-UI face of the schema work. #90 and #91 depend on #55 (membership exists). #93 → #94 → #95 are the DM session toolset; they depend on a running GameServer (i.e., #56 merged). #92 (spectator) is discovery and can be done any time but gates any spectator implementation.

---

## WP-G — Integration Test Coverage
_#76 and #77 are independent. #78 depends on WP-D (#54–#56)._

| # | Title | Priority |
|---|---|---|
| [#76](076-accounts-context-integration-tests.md) | `Accounts` context integration tests | medium |
| [#77](077-catalogue-cache-genserver-tests.md) | `Catalogue.Cache` GenServer tests | medium |
| [#78](078-game-live-event-handler-tests.md) | `GameLive` event handler integration tests | medium |

#76 and #77 can be done any time (no phase dependency). #78 requires WP-D (#54–#56) to be merged.

---

## WP-E — Admin App
_Mostly independent of the rules engine. Can be done in parallel with WP-D._

| # | Title | Priority |
|---|---|---|
| [#65](065-support-users-schema-and-auth.md) | `support_users` schema, migration, context, and auth | medium |
| [#64](064-admin-router-scope-and-pipeline.md) | Admin router scope and pipeline | medium |
| [#66](066-support-audit-log.md) | Support audit log | medium |
| [#67](067-admin-crud-users-and-campaigns.md) | Admin CRUD — Users and Campaigns | medium |
| [#75](075-admin-campaign-member-management.md) | Admin campaign member management | medium |
| [#69](069-metrics-store-behaviour-and-local-impl.md) | `MetricsStore` behaviour + `Stores.Local` impl | low |
| [#68](068-livedashboard-and-campaign-monitoring.md) | LiveDashboard mount + custom campaign monitoring | low |
| [#74](074-admin-character-moderation-view.md) | Admin character moderation view | low |

#65 is the foundation — everything else gates on it. #64 → #67 → (#74, #75). #69 is a prerequisite for #68.

---

## WP-F — Rendering & Frontend
_SVG pipeline bugs, viewport architecture, and art direction. Expanded with discoveries from brainstorm #14._

| # | Title | Priority |
|---|---|---|
| [#97](097-full-viewport-scene-layout.md) | Full-viewport scene layout model and overlay z-layer system (discovery) | medium |
| [#98](098-dst-art-direction-spec.md) | DST-inspired art direction — reference tile and entity spec | medium |
| [#13](013-move-overlay-depth-isometric.md) | Move overlay occluded by entities in isometric depth order | medium |
| [#25](025-ruleset-ui-declaration.md) | Ruleset UI declaration: action buttons + stat panels (discovery) | medium |
| [#26](026-fog-of-war-ownership.md) | Fog-of-war ownership: ruleset or engine? (discovery) | medium |
| [#34](034-active-effect-visual-and-animation.md) | Active effect visual representation and animation (discovery) | medium |
| [#99](099-multi-style-appearance-system.md) | Multi-style appearance system — `style_id` keying, per-style records, fallback | medium |
| [#100](100-svg-fragment-store-compositing.md) | SVG fragment store and compositing pipeline (discovery) | medium |
| [#81](081-viewport-zoom-pan-architecture.md) | Viewport zoom/pan architecture (discovery) | low |
| [#82](082-z-axis-elevation-projection-and-los.md) | Z-axis elevation — projection, depth sorting, and LOS (discovery) | low |
| [#83](083-volumetric-spell-effect-rendering.md) | Volumetric spell effect rendering (discovery) | low |
| [#84](084-lod-sprite-detail-levels-for-zoom.md) | LOD sprite detail levels for zoom (discovery) | low |
| [#101](101-dm-top-down-projection-mode.md) | DM top-down projection mode (discovery) | low |
| [#10](010-origin-x-non-square-maps.md) | Isometric `origin_x` formula breaks on non-square maps | low |
| [#21](021-dice-roll-cycling-faces.md) | Dice roll cycling faces | low |
| [#27](027-tile-decoration-storage.md) | Tile decoration storage (discovery) | low |
| [#28](028-multi-tile-entities.md) | Multi-tile entity footprints (discovery) | low |

Discovery issues must be answered before writing the corresponding rendering code. Suggested internal sequencing: #97 (viewport layout) and #98 (art direction) first — they unblock #81 (zoom/pan) and #99 (multi-style). #99 unblocks #100 (compositing). #84 (LOD) after #81 (zoom). #83 (volumetric) after #82 (elevation). #101 (top-down) is best after the coordinate system is projection-agnostic (which should be validated in #97).

---

## WP-H — Game Content *(new)*
_Content taxonomy and initial data population. Depends on WP-C (rules engine done) and needs legal clearance (#16) before any non-SRD content._

| # | Title | Priority |
|---|---|---|
| [#88](088-game-content-type-taxonomy.md) | Game content type taxonomy and upsert workflow (discovery) | medium |
| [#89](089-initial-game-content-population.md) | Initial content population — races, classes, starter monsters/items | low |

#88 is the discovery gate. #89 is blocked on #88 and on #16 (LPC sprite legal risk) for any non-SRD content. Art direction (#98 in WP-F) should be settled before the appearance slot in #88 is finalised, since it defines what a per-style appearance record contains.

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

WP-A, WP-B, and WP-C are complete. **Current critical path: WP-D (#54 → #55 → #56 → #57 → #90/#91 → #93 → #94 → #95).** WP-E, WP-F discoveries, and WP-H (#88) can run in parallel. WP-I (#96) is fully independent. WP-G #76 and #77 are free-floating.
