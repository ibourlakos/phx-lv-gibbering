# Issue Tracker

**Next issue number:** 102 (see `counter`)

One file per issue: `docs/issues/<N>-<slug>.md`. This file is the index only — no issue content lives here.

---

## Tags

| Tag | Scope |
|---|---|
| `bug` | Code correctness — crashes, wrong behaviour, wrong output |
| `rules` | D&D 5e SRD rules fidelity |
| `architecture` | Structural design — process model, data model, abstractions |
| `legal` | Licensing, IP, asset compliance |
| `ops` | Infrastructure, tooling, CI/CD, deployment |
| `discovery` | Open questions and design unknowns that need scoping before any code task can be derived |
| `rendering` | SVG pipeline, isometric projection, visual layers |
| `gameplay` | Game mechanics, player experience, game feel |
| `ui` | LiveView/frontend — components, forms, navigation, non-SVG views |
| `security` | Auth, authorization, access control, permissions |
| `admin` | Admin app — support users, moderation, LiveDashboard, catalogue management |

---

## Open Issues

| # | Title | Tags | Priority |
|---|---|---|---|
| [#63](063-playwright-smoke-tests.md) | Playwright smoke test suite + smoke Docker environment | `ops` `architecture` | low |
| [#68](068-livedashboard-and-campaign-monitoring.md) | LiveDashboard mount + custom campaign monitoring page | `ops` `architecture` | low |
| [#69](069-metrics-store-behaviour-and-local-impl.md) | `MetricsStore` behaviour + `Stores.Local` implementation | `architecture` `ops` | low |
| [#74](074-admin-character-moderation-view.md) | Admin character moderation view | `architecture` `gameplay` | low |
| [#6](006-raster-sprite-pipeline.md) | Raster sprite asset pipeline | `ops` `rendering` `legal` | low |
| [#10](010-origin-x-non-square-maps.md) | Isometric `origin_x` formula breaks on non-square maps | `bug` `rendering` | low |
| [#13](013-move-overlay-depth-isometric.md) | Move overlay occluded by entities in isometric depth order | `bug` `rendering` | medium |
| [#15](015-stats-map-tradeoff.md) | Document `stats: map()` tradeoffs for entity stats | `architecture` | low |
| [#16](016-lpc-sprite-license-risk.md) | LPC sprite copyleft risk understated in brainstorm | `legal` | medium |
| [#21](021-dice-roll-cycling-faces.md) | Dice roll shows final face during flight instead of cycling faces | `gameplay` `rendering` | low |
| [#24](024-grid-data-jsonb.md) | Consolidate grid_tiles rows into JSONB column | `architecture` `rendering` | low |
| [#25](025-ruleset-ui-declaration.md) | Ruleset UI declaration: action buttons and stat panels | `discovery` `architecture` | medium |
| [#26](026-fog-of-war-ownership.md) | Fog-of-war ownership: ruleset or engine? | `discovery` `architecture` `rendering` | medium |
| [#27](027-tile-decoration-storage.md) | Tile decoration storage: GridTile field vs decoration entity | `discovery` `architecture` `rendering` | low |
| [#28](028-multi-tile-entities.md) | Multi-tile entity footprints in isometric rendering | `discovery` `architecture` `rendering` | low |
| [#32](032-dm-override-event-schema.md) | DM override event schema and god-mode mechanics | `discovery` `architecture` `gameplay` | medium |
| [#33](033-templates-governance-model.md) | Templates governance model | `discovery` `architecture` | low |
| [#34](034-active-effect-visual-and-animation.md) | Active effect visual representation and animation | `discovery` `rendering` `gameplay` | medium |
| [#80](080-inventory-and-loot-container-system.md) | Inventory and loot container system | `discovery` `architecture` `gameplay` | low |
| [#81](081-viewport-zoom-pan-architecture.md) | Viewport zoom/pan architecture | `discovery` `rendering` `architecture` | low |
| [#82](082-z-axis-elevation-projection-and-los.md) | Z axis elevation — projection, depth sorting, and LOS | `discovery` `rendering` `architecture` | low |
| [#83](083-volumetric-spell-effect-rendering.md) | Volumetric spell effect rendering | `discovery` `rendering` | low |
| [#84](084-lod-sprite-detail-levels-for-zoom.md) | LOD sprite detail levels for zoom | `rendering` `architecture` | low |
| [#85](085-content-creation-tools-design.md) | Content creation tools — design and scope | `discovery` `architecture` `ui` `admin` | low |
| [#88](088-game-content-type-taxonomy.md) | Game content type taxonomy and upsert workflow | `discovery` `architecture` `gameplay` | medium |
| [#89](089-initial-game-content-population.md) | Initial game content population — races, classes, starter monsters/items | `gameplay` `rules` `admin` | low |
| [#92](092-spectator-role-discovery.md) | Spectator role — campaign membership and session view | `discovery` `architecture` `gameplay` | low |
| [#96](096-promex-prometheus-grafana-stack.md) | PromEx + Prometheus + Grafana monitoring stack | `ops` `architecture` | low |
| [#102](102-gamelive-full-viewport-layout-refactor.md) | GameLive full-viewport layout refactor | `rendering` `ui` `architecture` | medium |
| [#99](099-multi-style-appearance-system.md) | Multi-style appearance system — style_id keying, per-style records, fallback | `architecture` `rendering` | medium |
| [#100](100-svg-fragment-store-compositing.md) | SVG fragment store and compositing pipeline | `discovery` `rendering` `architecture` | medium |
| [#101](101-dm-top-down-projection-mode.md) | DM top-down projection mode | `discovery` `rendering` `architecture` | low |

---

## Deferred Issues

| # | Title | Tags | Priority |
|---|---|---|---|
| [#86](086-simplify-check-docs-to-git-diff-scope.md) | Simplify `mix check.docs` to git-diff scope | `ops` `architecture` | low |
| [#58](058-point-buy-ability-scores.md) | Point buy ability score method | `gameplay` `rules` | low |
| [#59](059-character-export-import.md) | Character export/import with versioned serialization | `architecture` `gameplay` | low |
| [#60](060-umbrella-restructure-for-admin-app.md) | Umbrella restructure for independent admin app deployment | `discovery` `architecture` `ops` | low |
| [#61](061-catalogue-entry-versioning.md) | Catalogue entry versioning | `discovery` `architecture` | low |
| [#62](062-multi-environment-infra.md) | Multi-environment infrastructure (QA + production) | `ops` `architecture` | low |
| [#70](070-ugc-content-schema-and-moderation.md) | UGC content schema, `content_trust` flag, and moderation queue | `architecture` `gameplay` | low |
| [#71](071-admin-catalogue-crud.md) | Admin catalogue CRUD | `architecture` `gameplay` | low |

---

## Blocked Issues

| # | Title | Tags | Priority | Blocked by |
|---|---|---|---|---|

---

## Cancelled Issues

| # | Title | Tags |
|---|---|---|

---

## Closed Issues

| # | Title | Tags |
|---|---|---|
| [#87](087-elixirls-hover-docs-docker-proxy.md) | ElixirLS hover documentation not working via Docker proxy | `ops` |
| [#1](001-establish-git-remote.md) | Establish git remote | `ops` |
| [#72](072-drop-users-role-column.md) | Drop `users.role` column | `architecture` |
| [#8](008-string-to-existing-atom-crash.md) | `String.to_existing_atom` crash in data pipeline parser | `bug` |
| [#9](009-tile-walkable-nil-crash.md) | `tile_walkable?` crashes on missing tile coordinates | `bug` |
| [#73](073-static-reference-data-to-db.md) | Migrate static reference data to DB tables | `architecture` `ops` |
| [#29](029-srd-data-ingestion-pipeline.md) | SRD data ingestion pipeline | `architecture` `ops` |
| [#3](003-saveload-order.md) | Save/load: before or after Ruleset behaviour split | `discovery` `architecture` |
| [#11](011-supervision-tree-design.md) | Supervision tree design for SceneServer processes | `architecture` |
| [#12](012-persistence-strategy.md) | Persistence strategy: game state → Postgres | `architecture` |
| [#14](014-ruleset-behaviour-vs-protocol.md) | `Gibbering.Ruleset`: behaviour vs protocol | `discovery` `architecture` |
| [#36](036-scene-phase-state-machine.md) | Scene phase state machine in `SceneServer` | `architecture` `rules` |
| [#39](039-ruleset-behaviour.md) | `Gibbering.Ruleset` behaviour + `DnD5e` implementation shell | `architecture` |
| [#31](031-rule-modifier-predicate-decomposition.md) | Trigger/predicate/effect decomposition for RuleModifier | `discovery` `rules` `architecture` |
| [#37](037-runtime-entity-map-extensions.md) | Runtime entity map: `action_economy`, `resources`, `conditions` fields | `architecture` `rules` |
| [#40](040-rule-modifier-predicate-evaluator.md) | `RuleModifier` struct + predicate evaluator + modifier pipeline | `rules` `architecture` |
| [#30](030-conditions-status-effects-model.md) | Conditions and status effects engine model | `rules` `architecture` |
| [#42](042-condition-struct.md) | `Condition` struct + runtime application via active effects registry | `rules` `gameplay` |
| [#43](043-action-economy-tracking.md) | Action economy tracking + `advance_turn` reset | `rules` `gameplay` |
| [#44](044-spell-slots-resource-pools.md) | Spell slots + class resource pools in `resources` map | `rules` `gameplay` |
| [#4](004-fog-vs-sprites.md) | Fog of war vs sprites: which comes first | `discovery` |
| [#5](005-isometric-rendering.md) | Isometric rendering overhaul (2:1 dimetric) | `rendering` |
| [#17](017-wizard-speed-nonstandard.md) | Wizard speed is non-standard (25 ft instead of 30 ft) | `bug` `rules` |
| [#18](018-player-session-identity.md) | Player session identity: persistent UUID per browser session | `architecture` `gameplay` |
| [#7](007-movement-distance-algorithm.md) | Movement distance algorithm is wrong for D&D 5e | `bug` `rules` `gameplay` |
| [#22](022-user-accounts-and-auth.md) | User accounts and authentication (player/dm/support roles) | `architecture` `gameplay` `ops` |
| [#23](023-campaign-membership.md) | Campaign membership and DM assignment | `architecture` `gameplay` |
| [#35](035-entity-schema-level-temp-hp.md) | Entity schema: add `level`, `temp_hp`, `challenge_rating`, `xp_reward` | `architecture` `rules` |
| [#38](038-dnd5e-stats-module.md) | `DnD5e.Stats`: derived stat computation module | `rules` `architecture` |
| [#45](045-attack-roll-vs-ac.md) | Attack roll vs AC (replace bare 1d6 in `Rules.attack/3`) | `rules` `gameplay` |
| [#46](046-equipped-item-jsonb.md) | Equipped weapon/armor in `stats` JSONB + seed data | `rules` `gameplay` |
| [#47](047-migrate-features-to-rule-modifiers.md) | Migrate `Data.Classes`/`Data.Races` features to `%RuleModifier{}` | `rules` |
| [#48](048-saving-throw-pipeline.md) | Saving throw pipeline | `rules` `gameplay` |
| [#49](049-backgrounds-catalogue-module.md) | Backgrounds catalogue module (`Data.Backgrounds`) | `rules` `gameplay` |
| [#50](050-character-schema-and-context.md) | Character schema and context (player-owned template) | `architecture` `gameplay` |
| [#51](051-character-collection-liveview.md) | Character collection LiveView (`/characters` roster) | `gameplay` `rendering` |
| [#52](052-character-creation-modal.md) | Character creation multi-step modal | `gameplay` `rendering` |
| [#53](053-composable-svg-appearance-system.md) | Composable SVG appearance system | `rendering` `architecture` |
| [#41](041-spell-struct.md) | `Spell` struct completion + `Data.Spells` migration | `rules` `gameplay` |
| [#79](079-data-items-catalogue-module.md) | `Data.Items` catalogue module | `rules` `gameplay` |
| [#19](019-lobby-edits-stale-gameserver.md) | Lobby character edits don't propagate to a running GameServer | `bug` `architecture` |
| [#20](020-spells-defined-not-castable.md) | Spells are defined but not castable | `gameplay` `rules` |
| [#2](002-wizard-first-mechanic.md) | Wizard first unique mechanic: ranged attack or AOE spell | `discovery` `gameplay` |
| [#91](091-campaign-invite-link-token.md) | Campaign invite link / shareable token mechanism | `architecture` `ui` `gameplay` |
| [#90](090-player-campaign-overview-page.md) | Player campaign overview page | `ui` `gameplay` |
| [#54](054-campaign-character-schema.md) | CampaignCharacter schema (template-to-instance bridge) | `architecture` `gameplay` |
| [#55](055-bidirectional-campaign-joining.md) | Bidirectional campaign joining (player request + DM invite) | `architecture` `gameplay` |
| [#56](056-character-template-merge-logic.md) | Character template → live entity merge logic | `architecture` `rules` |
| [#57](057-dm-character-adjustment-ui.md) | DM character adjustment UI (campaign prep) | `gameplay` `rendering` |
| [#76](076-accounts-context-integration-tests.md) | `Accounts` context integration tests | `architecture` `ops` |
| [#77](077-catalogue-cache-genserver-tests.md) | `Catalogue.Cache` GenServer tests | `architecture` `ops` |
| [#78](078-game-live-event-handler-tests.md) | `GameLive` event handler integration tests | `gameplay` `architecture` |
| [#93](093-dm-session-lifecycle-controls.md) | DM session lifecycle controls (start, pause, resume, end) | `ui` `gameplay` `architecture` |
| [#94](094-dm-initiative-panel.md) | DM turn and initiative management panel | `ui` `gameplay` |
| [#95](095-dm-intervention-toolset.md) | DM intervention toolset (broadcast, whisper, condition/HP override) | `ui` `gameplay` `architecture` |
| [#64](064-admin-router-scope-and-pipeline.md) | Admin router scope and pipeline | `architecture` `ops` |
| [#65](065-support-users-schema-and-auth.md) | `support_users` schema, migration, context, and auth | `architecture` `ops` |
| [#66](066-support-audit-log.md) | Support audit log | `architecture` `ops` |
| [#67](067-admin-crud-users-and-campaigns.md) | Admin CRUD — Users and Campaigns | `architecture` `gameplay` |
| [#75](075-admin-campaign-member-management.md) | Admin campaign member management | `architecture` `gameplay` |
| [#97](097-full-viewport-scene-layout.md) | Full-viewport scene layout model (discovery) | `discovery` `rendering` `architecture` `ui` |
| [#98](098-dst-art-direction-spec.md) | DST-inspired art direction spec (discovery) | `rendering` |
