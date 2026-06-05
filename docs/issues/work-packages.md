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
| #42 | `Condition` struct + runtime application via active effects | medium |
| #43 | Action economy tracking + `advance_turn` reset | medium |
| #44 | Spell slots + class resource pools in `resources` map | medium |
| #20 | Spells are defined but not castable | medium |
| #46 | Equipped weapon/armor in `stats` JSONB + seed data | low |
| #47 | Migrate `Data.Classes`/`Data.Races` features to `%RuleModifier{}` | low |
| #48 | Saving throw pipeline | low |

#31 is a design gate — resolve before writing any `RuleModifier` code. Ordering: #37 → (#40, #43, #44) → (#30, #42) → (#41, #20). #47 is a cleanup that can happen any time after #40.

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
| #10 | Isometric `origin_x` formula breaks on non-square maps | low |
| #21 | Dice roll cycling faces | low |
| #27 | Tile decoration storage (discovery) | low |
| #28 | Multi-tile entity footprints (discovery) | low |

The four discovery issues (#25, #26, #27, #28) are design questions that should be answered before writing rendering code. #13 is an independent bug fix.

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

---

## Suggested sequencing

```
WP-A  →  WP-B  →  WP-C  →  WP-D (frontend finish)
              ↘  WP-E  (parallel with WP-C)
              ↘  WP-F discoveries (parallel; rendering code gates on WP-C shape)
```

Highest-leverage near-term move: close #1 and #72 (quick housekeeping), resolve the #3 and #14 design decisions (they gate #39 and #12), then land WP-B as a milestone before touching rules or admin code.
