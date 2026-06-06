# Work Packages
_Temporary planning doc — not an issue file. Delete when packages are actioned._

Generated: 2026-06-05 · Last updated: 2026-06-06

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

## WP-D — Campaign & Character Lifecycle
_Bridges character-creation work (closed) to active play. Depends on WP-A schema work and WP-B entity merge._

| # | Title | Priority |
|---|---|---|
| [#54](054-campaign-character-schema.md) | `CampaignCharacter` schema (template-to-instance bridge) | medium |
| [#55](055-bidirectional-campaign-joining.md) | Bidirectional campaign joining (player request + DM invite) | medium |
| [#56](056-character-template-merge-logic.md) | Character template → live entity merge logic | medium |
| [#57](057-dm-character-adjustment-ui.md) | DM character adjustment UI (campaign prep) | medium |

#54 → #55 → #56 are strictly sequential. #57 is the frontend face of this package.

---

## WP-G — Integration Test Coverage
_Fills the remaining coverage gaps left after the pure-unit pass. #76 and #77 are independent; #78 depends on WP-D._

| # | Title | Priority |
|---|---|---|
| [#76](076-accounts-context-integration-tests.md) | `Accounts` context integration tests | medium |
| [#77](077-catalogue-cache-genserver-tests.md) | `Catalogue.Cache` GenServer tests | medium |
| [#78](078-game-live-event-handler-tests.md) | `GameLive` event handler integration tests | medium |

#76 and #77 can be done any time (no phase dependency). #78 requires WP-D (#54–#56) because event handlers need a live `CampaignCharacter` and a running `GameServer` backed by DB entities.

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

#65 is the foundation — everything else in this package gates on it. #64 → #67 → (#74, #75). #69 is a prerequisite for #68 but neither blocks other admin work.

---

## WP-F — Rendering & Frontend
_SVG pipeline bugs and discovery. Mostly depends on WP-B for data shape clarity._

| # | Title | Priority |
|---|---|---|
| [#13](013-move-overlay-depth-isometric.md) | Move overlay occluded by entities in isometric depth order | medium |
| [#25](025-ruleset-ui-declaration.md) | Ruleset UI declaration: action buttons + stat panels (discovery) | medium |
| [#26](026-fog-of-war-ownership.md) | Fog-of-war ownership: ruleset or engine? (discovery) | medium |
| [#34](034-active-effect-visual-and-animation.md) | Active effect visual representation and animation (discovery) | medium |
| [#81](081-viewport-zoom-pan-architecture.md) | Viewport zoom/pan architecture (discovery) | low |
| [#82](082-z-axis-elevation-projection-and-los.md) | Z-axis elevation — projection, depth sorting, and LOS (discovery) | low |
| [#83](083-volumetric-spell-effect-rendering.md) | Volumetric spell effect rendering (discovery) | low |
| [#84](084-lod-sprite-detail-levels-for-zoom.md) | LOD sprite detail levels for zoom (discovery) | low |
| [#10](010-origin-x-non-square-maps.md) | Isometric `origin_x` formula breaks on non-square maps | low |
| [#21](021-dice-roll-cycling-faces.md) | Dice roll cycling faces | low |
| [#27](027-tile-decoration-storage.md) | Tile decoration storage (discovery) | low |
| [#28](028-multi-tile-entities.md) | Multi-tile entity footprints (discovery) | low |

Discovery issues (#25, #26, #27, #28, #81, #82, #83, #84) must be answered before writing the corresponding rendering code. #13 and #10 are independent bug fixes. #84 (LOD) should be resolved after or alongside #81 (viewport zoom). #83 (volumetric effects) is best after #82 (elevation) but can ship flat first.

---

## Cross-cutting Threads
_No strict phase placement. Resolve in parallel or as needed._

| # | Title | Notes |
|---|---|---|
| [#16](016-lpc-sprite-license-risk.md) | LPC sprite copyleft risk | Legal — blocks #6 |
| [#6](006-raster-sprite-pipeline.md) | Raster sprite asset pipeline | Blocked on #16 |
| [#19](019-lobby-edits-stale-gameserver.md) | Lobby edits don't propagate to running GameServer | Bug — no WP home yet |
| [#32](032-dm-override-event-schema.md) | DM override event schema and god-mode mechanics | Discovery |
| [#33](033-templates-governance-model.md) | Templates governance model | Discovery |
| [#63](063-playwright-smoke-tests.md) | Playwright smoke tests + smoke Docker env | Ops |
| [#80](080-inventory-and-loot-container-system.md) | Inventory and loot container system | Discovery — depends on #79 + WP-C |
| [#85](085-content-creation-tools-design.md) | Content creation tools — design and scope | Discovery — spans WP-E + future UGC |

---

## Suggested sequencing

```
WP-A ✓  →  WP-B ✓  →  WP-C ✓  →  WP-D  →  WP-G (#78)
                       ↘  WP-E  (parallel with WP-D)
                       ↘  WP-F discoveries (parallel; rendering code gates on WP-D shape)
                          WP-G (#76, #77 free-floating — can start now)
```

WP-A, WP-B, and WP-C are complete. Current critical path: WP-D (#54 → #55 → #56 → #57). WP-E (#65 is its foundation) and WP-F discoveries can run in parallel. WP-G issues #76 and #77 are free-floating and can be picked up any time.
