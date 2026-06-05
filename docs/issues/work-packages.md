# Work Packages
_Temporary planning doc — not an issue file. Delete when packages are actioned._

Generated: 2026-06-05

---

## WP-A — Infrastructure & Data Plumbing
_Unblocks everything else. Do these early._

| # | Title | Priority |
|---|---|---|
| #1 | Establish git remote | high |
| #72 | Drop `users.role` column | high |
| #8 | `String.to_existing_atom` crash in data pipeline | medium |
| #9 | `tile_walkable?` crash on missing coords | medium |
| #73 | Migrate static reference data to DB tables | medium |
| #29 | SRD data ingestion pipeline | medium |
| #24 | Consolidate `grid_tiles` rows into JSONB column | low |

#73 and #29 are sequenced — ingest pipeline (#29) feeds the reference tables (#73). #72 is an independent cleanup but should land before admin work starts since it touches the auth model.

---

## WP-B — Core Engine Architecture
_Process model, supervision, persistence. The skeleton the rules engine hangs on._

| # | Title | Priority |
|---|---|---|
| #11 | Supervision tree design for `GameServer` | high |
| #12 | Persistence strategy: game state → Postgres | high |
| #36 | Scene phase state machine in `SceneServer` | high |
| #39 | `Gibbering.Ruleset` behaviour + `DnD5e` shell | high |
| #14 | `Ruleset`: behaviour vs protocol (discovery) | medium |
| #3 | Save/load: before or after Ruleset split (discovery) | medium |
| #15 | Document `stats: map()` tradeoffs | low |

#39 closes #14. #3 is a prerequisite decision for #12. #36 depends on #11.

---

## WP-C — Rules Engine
_D&D 5e logic: modifiers, conditions, economy, spells. Depends on WP-B._

| # | Title | Priority |
|---|---|---|
| #31 | Trigger/predicate/effect decomposition for `RuleModifier` (discovery) | high |
| #37 | Runtime entity map: `action_economy`, `resources`, `conditions` | high |
| #40 | `RuleModifier` struct + predicate evaluator + modifier pipeline | medium |
| #30 | Conditions and status effects engine model | medium |
| #41 | `Spell` struct completion + `Data.Spells` migration | medium |
| #79 | `Data.Items` catalogue module (weapons, armour, consumables) | low |
| #42 | `Condition` struct + runtime application via active effects | medium |
| #43 | Action economy tracking + `advance_turn` reset | medium |
| #44 | Spell slots + class resource pools in `resources` map | medium |
| #20 | Spells are defined but not castable | medium |
| #46 | Equipped weapon/armor in `stats` JSONB + seed data | low |
| #47 | Migrate `Data.Classes`/`Data.Races` features to `%RuleModifier{}` | low |
| #48 | Saving throw pipeline | low |

#31 is a design gate — resolve before writing any `RuleModifier` code. Ordering: #37 → (#40, #43, #44) → (#30, #42) → (#41, #79, #20). #47 is a cleanup that can happen any time after #40. #79 can be done any time alongside #41 — both are pure catalogue data modules with no rule engine dependency.

---

## WP-D — Campaign & Character Lifecycle
_Bridges character-creation work (closed) to active play. Depends on WP-A schema work and WP-B entity merge._

| # | Title | Priority |
|---|---|---|
| #54 | `CampaignCharacter` schema (template-to-instance bridge) | medium |
| #55 | Bidirectional campaign joining (player request + DM invite) | medium |
| #56 | Character template → live entity merge logic | medium |
| #57 | DM character adjustment UI (campaign prep) | medium |

#54 → #55 → #56 are strictly sequential. #57 is the frontend face of this package.

---

## WP-G — Integration Test Coverage
_Fills the remaining coverage gaps left after the pure-unit pass. #76 and #77 are independent; #78 depends on WP-D._

| # | Title | Priority |
|---|---|---|
| #76 | `Accounts` context integration tests | medium |
| #77 | `Catalogue.Cache` GenServer tests | medium |
| #78 | `GameLive` event handler integration tests | medium |

#76 and #77 can be done any time (no phase dependency). #78 requires WP-D (#54–#56) because event handlers need a live `CampaignCharacter` and a running `GameServer` backed by DB entities.

---

## WP-E — Admin App
_Mostly independent of the rules engine. Can be done in parallel with WP-C._

| # | Title | Priority |
|---|---|---|
| #65 | `support_users` schema, migration, context, and auth | medium |
| #64 | Admin router scope and pipeline | medium |
| #66 | Support audit log | medium |
| #67 | Admin CRUD — Users and Campaigns | medium |
| #75 | Admin campaign member management | medium |
| #69 | `MetricsStore` behaviour + `Stores.Local` impl | low |
| #68 | LiveDashboard mount + custom campaign monitoring | low |
| #74 | Admin character moderation view | low |

#65 is the foundation — everything else in this package gates on it. #64 → #67 → (#74, #75). #69 is a prerequisite for #68 but neither blocks other admin work.

---

## WP-F — Rendering & Frontend
_SVG pipeline bugs and discovery. Mostly depends on WP-B for data shape clarity._

| # | Title | Priority |
|---|---|---|
| #13 | Move overlay occluded by entities in isometric depth order | medium |
| #25 | Ruleset UI declaration: action buttons + stat panels (discovery) | medium |
| #26 | Fog-of-war ownership: ruleset or engine? (discovery) | medium |
| #34 | Active effect visual representation and animation (discovery) | medium |
| #81 | Viewport zoom/pan architecture (discovery) | low |
| #82 | Z-axis elevation — projection, depth sorting, and LOS (discovery) | low |
| #83 | Volumetric spell effect rendering (discovery) | low |
| #84 | LOD sprite detail levels for zoom (discovery) | low |
| #10 | Isometric `origin_x` formula breaks on non-square maps | low |
| #21 | Dice roll cycling faces | low |
| #27 | Tile decoration storage (discovery) | low |
| #28 | Multi-tile entity footprints (discovery) | low |

Discovery issues (#25, #26, #27, #28, #81, #82, #83, #84) must be answered before writing the corresponding rendering code. #13 and #10 are independent bug fixes. #84 (LOD) should be resolved after or alongside #81 (viewport zoom) since zoom thresholds are jointly determined. #83 (volumetric effects) is best after #82 (elevation) but can ship flat (z=0 only) first.

---

## Cross-cutting Threads
_No strict phase placement. Resolve in parallel or as needed._

| # | Title | Notes |
|---|---|---|
| #16 | LPC sprite copyleft risk | Legal — blocks #6 |
| #6 | Raster sprite asset pipeline | Blocked on #16 |
| #2 | Wizard first unique mechanic | Discovery/gameplay |
| #32 | DM override event schema and god-mode mechanics | Discovery |
| #33 | Templates governance model | Discovery |
| #63 | Playwright smoke tests + smoke Docker env | Ops |
| #80 | Inventory and loot container system | Discovery — depends on #79 + #40 (RuleModifier pipeline) |
| #85 | Content creation tools — design and scope | Discovery — spans WP-E admin shell and future player UGC |

---

## Suggested sequencing

```
WP-A  →  WP-B  →  WP-C  →  WP-D  →  WP-G (#78)
              ↘  WP-E  (parallel with WP-C)        ↗ WP-G (#76, #77 can start earlier)
              ↘  WP-F discoveries (parallel; rendering code gates on WP-C shape)
```

WP-A and WP-B are closed. Next on the critical path: resolve #31 (RuleModifier design gate) to unblock WP-C. WP-E (Admin App) can start in parallel with WP-C — #65 is its foundation. WP-G issues #76 and #77 are free-floating and can be picked up any time.
