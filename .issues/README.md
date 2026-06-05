# Issue Tracker

**Next issue number:** 49 (see `counter`)

One file per issue: `.issues/<N>-<slug>.md`. This file is the index only — no issue content lives here.

---

## Tags

| Tag | Scope |
|---|---|
| `bug` | Code correctness — crashes, wrong behaviour, wrong output |
| `rules` | D&D 5e SRD rules fidelity |
| `architecture` | Structural design decisions — process model, data model, abstractions |
| `legal` | Licensing, IP, asset compliance |
| `ops` | Infrastructure, tooling, CI/CD, deployment |
| `discovery` | Open questions, design unknowns, and deferred design explorations that need scoping or structured discussion before any code task can be derived |
| `rendering` | SVG pipeline, isometric projection, visual layers |
| `gameplay` | Game feel, mechanics, player experience |

---

## Open Issues

| # | Title | Tags | Priority |
|---|---|---|---|
| [#1](001-establish-git-remote.md) | Establish git remote | `ops` | high |
| [#2](002-wizard-first-mechanic.md) | Wizard first unique mechanic: ranged attack or AOE spell | `discovery` `gameplay` | medium |
| [#3](003-saveload-order.md) | Save/load: before or after Ruleset behaviour split | `discovery` `architecture` | medium |
| [#6](006-raster-sprite-pipeline.md) | Raster sprite asset pipeline | `ops` `rendering` `legal` | low |
| [#8](008-string-to-existing-atom-crash.md) | `String.to_existing_atom` crash in data pipeline parser | `bug` | medium |
| [#9](009-tile-walkable-nil-crash.md) | `tile_walkable?` crashes on missing tile coordinates | `bug` | medium |
| [#10](010-origin-x-non-square-maps.md) | Isometric `origin_x` formula breaks on non-square maps | `bug` `rendering` | low |
| [#11](011-supervision-tree-design.md) | Supervision tree design for GameServer processes | `architecture` | high |
| [#12](012-persistence-strategy.md) | Persistence strategy: game state → Postgres | `architecture` | high |
| [#13](013-move-overlay-depth-isometric.md) | Move overlay occluded by entities in isometric depth order | `bug` `rendering` | medium |
| [#14](014-ruleset-behaviour-vs-protocol.md) | `Gibbering.Ruleset`: behaviour vs protocol | `discovery` `architecture` | medium |
| [#15](015-stats-map-tradeoff.md) | Document `stats: map()` tradeoffs for entity stats | `architecture` | low |
| [#16](016-lpc-sprite-license-risk.md) | LPC sprite copyleft risk understated in brainstorm | `legal` | medium |
| [#19](019-lobby-edits-stale-gameserver.md) | Lobby character edits don't propagate to a running GameServer | `bug` `architecture` | medium |
| [#20](020-spells-defined-not-castable.md) | Spells are defined but not castable | `gameplay` `rules` | medium |
| [#21](021-dice-roll-cycling-faces.md) | Dice roll shows final face during flight instead of cycling faces | `gameplay` `rendering` | low |
| [#24](024-grid-data-jsonb.md) | Consolidate grid_tiles rows into JSONB column | `architecture` `rendering` | low |
| [#25](025-ruleset-ui-declaration.md) | Ruleset UI declaration: action buttons and stat panels | `discovery` `architecture` | medium |
| [#26](026-fog-of-war-ownership.md) | Fog-of-war ownership: ruleset or engine? | `discovery` `architecture` `rendering` | medium |
| [#27](027-tile-decoration-storage.md) | Tile decoration storage: GridTile field vs decoration entity | `discovery` `architecture` `rendering` | low |
| [#28](028-multi-tile-entities.md) | Multi-tile entity footprints in isometric rendering | `discovery` `architecture` `rendering` | low |
| [#29](029-srd-data-ingestion-pipeline.md) | SRD data ingestion pipeline | `architecture` `ops` | medium |
| [#30](030-conditions-status-effects-model.md) | Conditions and status effects engine model | `rules` `architecture` | medium |
| [#31](031-rule-modifier-predicate-decomposition.md) | Trigger/predicate/effect decomposition for RuleModifier | `discovery` `rules` `architecture` | high |
| [#32](032-dm-override-event-schema.md) | DM override event schema and god-mode mechanics | `discovery` `architecture` `gameplay` | medium |
| [#33](033-templates-governance-model.md) | Templates governance model | `discovery` `architecture` | low |
| [#34](034-active-effect-visual-and-animation.md) | Active effect visual representation and animation | `discovery` `rendering` `gameplay` | medium |
| [#36](036-scene-phase-state-machine.md) | Scene phase state machine in `SceneServer` | `architecture` `rules` | high |
| [#37](037-runtime-entity-map-extensions.md) | Runtime entity map: `action_economy`, `resources`, `conditions` fields | `architecture` `rules` | high |
| [#39](039-ruleset-behaviour.md) | `Gibbering.Ruleset` behaviour + `DnD5e` implementation shell | `architecture` | high |
| [#40](040-rule-modifier-predicate-evaluator.md) | `RuleModifier` struct + predicate evaluator + modifier pipeline | `rules` `architecture` | medium |
| [#41](041-spell-struct.md) | `Spell` struct completion + `Data.Spells` migration | `rules` `gameplay` | medium |
| [#42](042-condition-struct.md) | `Condition` struct + runtime application via active effects registry | `rules` `gameplay` | medium |
| [#43](043-action-economy-tracking.md) | Action economy tracking + `advance_turn` reset | `rules` `gameplay` | medium |
| [#44](044-spell-slots-resource-pools.md) | Spell slots + class resource pools in `resources` map | `rules` `gameplay` | medium |
| [#45](045-attack-roll-vs-ac.md) | Attack roll vs AC (replace bare 1d6 in `Rules.attack/3`) | `rules` `gameplay` | high |
| [#46](046-equipped-item-jsonb.md) | Equipped weapon/armor in `stats` JSONB + seed data | `rules` `gameplay` | low |
| [#47](047-migrate-features-to-rule-modifiers.md) | Migrate `Data.Classes`/`Data.Races` features to `%RuleModifier{}` | `rules` | low |
| [#48](048-saving-throw-pipeline.md) | Saving throw pipeline | `rules` `gameplay` | low |

---

## Deferred Issues

| # | Title | Tags | Priority |
|---|---|---|---|

---

## Closed Issues

| # | Title | Tags |
|---|---|---|
| [#4](004-fog-vs-sprites.md) | Fog of war vs sprites: which comes first | `discovery` |
| [#5](005-isometric-rendering.md) | Isometric rendering overhaul (2:1 dimetric) | `rendering` |
| [#17](017-wizard-speed-nonstandard.md) | Wizard speed is non-standard (25 ft instead of 30 ft) | `bug` `rules` |
| [#18](018-player-session-identity.md) | Player session identity: persistent UUID per browser session | `architecture` `gameplay` |
| [#7](007-movement-distance-algorithm.md) | Movement distance algorithm is wrong for D&D 5e | `bug` `rules` `gameplay` |
| [#22](022-user-accounts-and-auth.md) | User accounts and authentication (player/dm/support roles) | `architecture` `gameplay` `ops` |
| [#23](023-campaign-membership.md) | Campaign membership and DM assignment | `architecture` `gameplay` |
| [#35](035-entity-schema-level-temp-hp.md) | Entity schema: add `level`, `temp_hp`, `challenge_rating`, `xp_reward` | `architecture` `rules` |
| [#38](038-dnd5e-stats-module.md) | `DnD5e.Stats`: derived stat computation module | `rules` `architecture` |
