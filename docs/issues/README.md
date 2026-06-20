# Issue Tracker

**Next issue number:** 161 (see `counter`)

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
| [#85](085-content-creation-tools-design.md) | Content creation tools — design and scope | `discovery` `architecture` `ui` `admin` | low |
| [#6](006-raster-sprite-pipeline.md) | Raster sprite asset pipeline | `ops` `rendering` `legal` | low |
| [#15](015-stats-map-tradeoff.md) | Document `stats: map()` tradeoffs for entity stats | `architecture` | low |
| [#21](021-dice-roll-cycling-faces.md) | Dice roll shows final face during flight instead of cycling faces | `gameplay` `rendering` | low |
| [#24](024-grid-data-jsonb.md) | Consolidate grid_tiles rows into JSONB column | `architecture` `rendering` | low |
| [#125](125-tile-decoration-field-and-rendering.md) | Tile decoration field and rendering | `architecture` `rendering` | low |
| [#84](084-lod-sprite-detail-levels-for-zoom.md) | LOD sprite detail levels for zoom | `rendering` `architecture` | low |
| [#121](121-spectator-membership-model.md) | Campaign membership: spectator role and invite flow | `architecture` `gameplay` | low |
| [#122](122-spectator-session-view.md) | Spectator session view: shared GameLive mount, full-map default, PC-perspective toggle | `architecture` `ui` `gameplay` | low |
| [#123](123-projection-behaviour-modules.md) | `Projection` behaviour: Isometric + TopDown modules, renderer audit | `architecture` `rendering` | low |
| [#124](124-dm-top-down-viewport.md) | DM top-down viewport: toggle, entity circles, grid labels, hover tooltip | `rendering` `ui` `architecture` | low |
| [#138](138-stray-active-entity-indicator.md) | Stray yellow circle on active entity indicator | `rendering` `bug` | low |
| [#140](140-invert-scroll-wheel-zoom.md) | Invert scroll wheel zoom direction | `ui` `rendering` | low |
| [#141](141-seeds-decomposition.md) | Decompose seeds.exs into per-concern sub-files | `ops` `architecture` | low |
| [#144](144-movement-confirmation-ui-gate.md) | Movement confirmation UI gate | `ui` `gameplay` `rendering` | medium |
| [#148](148-aoe-saving-throw-prompts.md) | AoE saving throw prompts — multi-owner concurrent rolls | `gameplay` `rules` `architecture` | medium |
| [#149](149-npc-dm-roll-visibility.md) | NPC / DM roll visibility | `gameplay` `ui` `architecture` | low |
| [#152](152-action-struct-v1-refactor.md) | Unify weapon attack and spell resolution under `%Action{}` — v1 refactor | `architecture` `rules` `gameplay` | medium |
| [#153](153-svg-testability-data-attributes-floki.md) | SVG testability — data attributes and Floki assertion layer | `ops` `architecture` `rendering` | medium |
| [#155](155-composable-entity-appearance-pipeline.md) | Composable entity appearance pipeline — archetype render system v1 | `rendering` `architecture` | low |
| [#156](156-coordinate-model-formalization.md) | Coordinate model formalization — game grid, SVG space, surface addresses, edge model | `architecture` `rendering` | medium |
| [#157](157-tile-occupancy-model.md) | Tile occupancy model — 5-category taxonomy, traversability function, entry triggers | `architecture` `gameplay` `rules` | medium |
| [#158](158-elevation-model.md) | Elevation model — integer Z, render sort, iso_project formula, staircase objects | `architecture` `rendering` `gameplay` | medium |
| [#159](159-condition-badge-overlay.md) | Condition badge overlay on entity tokens | `rendering` `gameplay` `ui` | medium |
| [#160](160-ui-layer-audit-and-layout-review.md) | UI layer audit — z-index stack and panel layout review | `ui` `rendering` `architecture` | medium |

---

## Deferred Issues

| # | Title | Tags | Priority |
|---|---|---|---|
| [#150](150-campaign-narrative-shell.md) | Campaign narrative shell (intro/outro text, encounter title) | `gameplay` `ui` | low |
| [#151](151-campaign-scene-phase-2-scene-templates.md) | Campaign / Scene Phase 2 — scene_templates and campaign_scenes schema | `architecture` `gameplay` | medium |
| [#86](086-simplify-check-docs-to-git-diff-scope.md) | Simplify `mix check.docs` to git-diff scope | `ops` `architecture` | low |
| [#58](058-point-buy-ability-scores.md) | Point buy ability score method | `gameplay` `rules` | low |
| [#59](059-character-export-import.md) | Character export/import with versioned serialization | `architecture` `gameplay` | low |
| [#60](060-umbrella-restructure-for-admin-app.md) | Umbrella restructure for independent admin app deployment | `discovery` `architecture` `ops` | low |
| [#61](061-catalogue-entry-versioning.md) | Catalogue entry versioning | `discovery` `architecture` | low |
| [#62](062-multi-environment-infra.md) | Multi-environment infrastructure (QA + production) | `ops` `architecture` | low |
| [#70](070-ugc-content-schema-and-moderation.md) | UGC content schema, `content_trust` flag, and moderation queue | `architecture` `gameplay` | low |
| [#71](071-admin-catalogue-crud.md) | Admin catalogue CRUD | `architecture` `gameplay` | low |
| [#96](096-promex-prometheus-grafana-stack.md) | PromEx + Prometheus + Grafana monitoring stack | `ops` `architecture` | low |
| [#120](120-items-data-population.md) | Items data module population — ≥20 SRD-legal items with appearance records | `gameplay` `rules` `architecture` | low |
| [#33](033-templates-governance-model.md) | Templates governance model | `discovery` `architecture` | low |
| [#28](028-multi-tile-entities.md) | Multi-tile entity footprints in isometric rendering | `discovery` `architecture` `rendering` | low |
| [#83](083-volumetric-spell-effect-rendering.md) | Volumetric spell effect rendering | `discovery` `rendering` | low |

---

## Blocked Issues

| # | Title | Tags | Priority | Blocked by |
|---|---|---|---|---|

---

## Cancelled Issues

| # | Title | Tags |
|---|---|---|
| [#82](082-z-axis-elevation-projection-and-los.md) | Z axis elevation — projection, depth sorting, and LOS | `discovery` `rendering` `architecture` |

---

## Closed Issues

| # | Title | Tags |
|---|---|---|
| [#147](147-initiative-roll-prompt.md) | Initiative roll prompt | `gameplay` `rules` `architecture` |
| [#146](146-dice-roll-prompt-component.md) | Dice roll prompt component + SceneServer pending-roll state | `ui` `gameplay` `architecture` `rules` |
| [#145](145-player-auto-roll-preference.md) | Player auto-roll preference | `architecture` `gameplay` `rules` |
| [#143](143-campaign-outcome-screen.md) | Campaign outcome screen | `ui` `gameplay` |
| [#139](139-dm-cannot-control-orphaned-pc.md) | DM cannot control orphaned PC — no action bar shown | `gameplay` `ui` `bug` |
| [#142](142-victory-defeat-scene-phases.md) | Victory and defeat scene phases + auto-trigger | `architecture` `gameplay` `rules` |
| [#132](132-scene-entity-appearance-catalogue-and-seeds.md) | Scene entity appearance catalogue and dev seed coverage | `gameplay` `rendering` `architecture` |
| [#154](154-dm-panel-redesign.md) | DM panel redesign — right panel DM tab entity catalog + intervention modal | `ui` `gameplay` `architecture` |
| [#137](137-right-panel-event-feed.md) | Right panel shell + player event feed + active links | `ui` `gameplay` `architecture` |
| [#136](136-event-visibility-and-dm-reveal.md) | Event visibility taxonomy + LogEntryRevealed / LogEntryHidden event structs | `architecture` `gameplay` `ui` |
| [#135](135-left-inspection-panel.md) | Left inspection panel — click-to-inspect map elements | `ui` `gameplay` `rendering` |
| [#134](134-rename-selected-id-to-actor-id.md) | Rename `selected_id` → `actor_id`; introduce `panel_subject` socket assign | `architecture` `ui` |
| [#133](133-introduce-docs-reference-folder.md) | Introduce `docs/reference/` for vocabulary and reference documents | `architecture` |
| [#127](127-item-pickup-event-loop.md) | Item pickup event loop — SceneServer handlers, Inventory pure module, container panel LiveView | `gameplay` `architecture` `ui` |
| [#128](128-equipped-item-collect-modifiers-integration.md) | Equipped item `collect_modifiers` integration — `Data.Items` modifiers + `:equipped_items` pipeline source | `rules` `architecture` |
| [#126](126-inventory-and-container-data-model.md) | Inventory and container data model — `object_subtype`/`items`/`inventory` stats keys, `Inventory` helper, LootSource seed | `architecture` `gameplay` |
| [#131](131-entity-movement-stats-and-valid-moves.md) | Entity movement stats (climb/swim/fly speeds) + `valid_moves` multi-mode deduction | `gameplay` `rules` |
| [#130](130-grid-tile-movement-jsonb.md) | `GridTile.movement` JSONB — replace `walkable: boolean`, entity movement overlay, valid_moves merge | `architecture` `gameplay` |
| [#129](129-maps-table-phase-1-migration.md) | Phase 1: introduce `maps` table (x_extent/y_extent, grid_tiles FK, SceneServer map_id) | `architecture` `ops` |
| [#114](114-observability-admin-direct-scene-reads.md) | Observability and admin: replace direct SceneServer reads with event subscriptions | `architecture` `admin` |
| [#113](113-cqrs-read-model-formalization.md) | CQRS read model formalization — explicit projections per adapter | `discovery` `architecture` |
| [#112](112-bounded-context-map-document.md) | Bounded context map document — integration patterns at each seam | `discovery` `architecture` |
| [#34](034-active-effect-visual-and-animation.md) | Active effect visual representation and animation | `discovery` `rendering` `gameplay` |
| [#25](025-ruleset-ui-declaration.md) | Ruleset UI declaration: action buttons and stat panels | `discovery` `architecture` |
| [#32](032-dm-override-event-schema.md) | DM override event schema and god-mode mechanics | `discovery` `architecture` `gameplay` |
| [#16](016-lpc-sprite-license-risk.md) | LPC sprite copyleft risk understated in brainstorm | `legal` |
| [#26](026-fog-of-war-ownership.md) | Fog-of-war ownership: ruleset or engine? | `discovery` `architecture` `rendering` |
| [#106](106-event-schema-design-methodology.md) | Event schema design methodology — Published Language mini-cycle | `architecture` `discovery` |
| [#111](111-event-cascade-batch-emission.md) | Event cascade batch emission — Event Aggregator pattern | `discovery` `architecture` |
| [#118](118-liveview-event-projection.md) | LiveView event projection from %EventBatch{} | `architecture` `ui` |
| [#92](092-spectator-role-discovery.md) | Spectator role — campaign membership and session view | `discovery` `architecture` `gameplay` |
| [#101](101-dm-top-down-projection-mode.md) | DM top-down projection mode | `discovery` `rendering` `architecture` |
| [#27](027-tile-decoration-storage.md) | Tile decoration storage: GridTile field vs decoration entity | `discovery` `architecture` `rendering` |
| [#80](080-inventory-and-loot-container-system.md) | Inventory and loot container system | `discovery` `architecture` `gameplay` |
| [#116](116-sceneserver-coexist-typed-event-broadcast.md) | SceneServer: replace bare-tuple broadcasts with typed %EventBatch{} | `architecture` `rules` |
| [#115](115-notification-event-structs-topic-migration.md) | Notification event structs and dedicated topic migration | `architecture` `ui` |
| [#119](119-scene-event-struct-definitions.md) | Scene event struct definitions — Gibbering.Events.* Published Language registry | `architecture` `rules` |
| [#117](117-architecture-doc-published-language-registry.md) | Architecture doc: document Gibbering.Events as Published Language registry | `architecture` |
| [#108](108-eventbus-behaviour-port-and-adapters.md) | EventBus behaviour: port and adapters — PubSub behind a port | `architecture` |
| [#110](110-sceneserver-single-writer-contract.md) | SceneServer single-writer contract — scene event stream ownership | `architecture` |
| [#109](109-compound-bus-command-event-separation.md) | Compound bus: command/event bus separation — B=(C,E) enforcement | `discovery` `architecture` |
| [#107](107-bounded-context-module-namespace-alignment.md) | Bounded context module namespace alignment — polytope naming | `discovery` `architecture` |
| [#105](105-polytope-architecture-treatise.md) | Polytope architecture model — mini-treatise and terminology reference | `architecture` `discovery` |
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
| [#102](102-gamelive-full-viewport-layout-refactor.md) | GameLive full-viewport layout refactor | `rendering` `ui` `architecture` |
| [#13](013-move-overlay-depth-isometric.md) | Move overlay occluded by entities in isometric depth order | `bug` `rendering` |
| [#10](010-origin-x-non-square-maps.md) | Isometric `origin_x` formula breaks on non-square maps | `bug` `rendering` |
| [#81](081-viewport-zoom-pan-architecture.md) | Viewport zoom/pan architecture | `discovery` `rendering` `architecture` |
| [#103](103-panzoom-hook-gestures.md) | PanZoom JS hook: pointer drag, wheel zoom, follow active token | `rendering` `architecture` `ui` |
| [#99](099-multi-style-appearance-system.md) | Multi-style appearance system — style_id keying, per-style records, fallback | `architecture` `rendering` |
| [#100](100-svg-fragment-store-compositing.md) | SVG fragment store and compositing pipeline | `discovery` `rendering` `architecture` |
| [#104](104-sprite-compositor-gameview-wiring.md) | Wire SpriteCompositor into GameLive entity rendering | `rendering` `architecture` `ui` |
| [#88](088-game-content-type-taxonomy.md) | Game content type taxonomy and upsert workflow | `discovery` `architecture` `gameplay` |
| [#89](089-initial-game-content-population.md) | Initial game content population — races, classes, starter monsters/items | `gameplay` `rules` `admin` |
| [#74](074-admin-character-moderation-view.md) | Admin character moderation view | `architecture` `gameplay` |
| [#68](068-livedashboard-and-campaign-monitoring.md) | LiveDashboard mount + custom campaign monitoring page | `ops` `architecture` |
| [#69](069-metrics-store-behaviour-and-local-impl.md) | `MetricsStore` behaviour + `Stores.Local` implementation | `architecture` `ops` |
