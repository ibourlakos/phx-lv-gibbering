# BS-17 · Campaign / Scene / Map Structure

**Opened:** 2026-06-13  
**Status:** open

---

## Context

The current data model hard-codes **1 campaign = 1 map = 1 scene**:

- `campaigns` carries `map_width`, `map_height`, `tile_size`
- `grid_tiles` and `entities` belong directly to a campaign
- `SceneServer` is keyed by `campaign_id` and holds one `%Engine.State{}`

A real D&D campaign runs multiple encounters across multiple maps (dungeon room, overworld, tavern, etc.). Several in-flight issues are about to build on the current flat structure — tile decorations (#125), inventory (#126–#128), spectator view (#121–#122). Before any of those are implemented, we need to decide whether the single-map assumption stays or whether a `maps`/`scenes` layer is introduced between `campaigns` and tiles/entities.

---

## Conceptual framing

### Narrative model (from *Formalization and Visualization of the Narrative for Museum Guides*, Bourlakos et al. 2017)

The paper proposes a three-level hierarchy with a clean separation of concerns that maps well onto a D&D campaign:

| Paper concept | D&D analogue |
|---|---|
| **Narrative** | Campaign (goals, constraints, DM, player roster) |
| **Segment** | Scene / Encounter (atomic unit of play) |
| **Exhibit** (location) | Map (the spatial substrate a scene takes place on) |
| **Movement segment** | Transition (travel between maps, no encounter content) |

The critical insight: a **map is an attribute of a scene**, not its parent container. Multiple scenes can reference the same map (e.g. the same dungeon room revisited later in the campaign). A campaign does not "contain" maps — it contains scenes, and scenes reference maps. This inverts the current schema's containment (`campaigns → grid_tiles`) and points toward a `scenes` table with a `map_id` FK.

### Community TTRPG hierarchy

The TTRPG community converges on three levels across multiple sources (D&D Beyond, The Angry GM, Campaign Mastery):

| Level | Theatrical analogue | Scope |
|---|---|---|
| **Encounter** | Scene | Single location, single conflict, < 1 session |
| **Adventure** | Act / episode | Sequence of encounters, shared story arc |
| **Campaign** | Series / franchise | Full arc, multiple adventures |

The Angry GM's framing: acts aren't containers — they're the *spaces between plot points* (turning points). Scenes are where plot points occur. This means scene sequencing (what unlocks what) is a runtime/narrative concern, not a schema hierarchy concern.

### Scene content layer

A scene is not just a map reference — it carries a **content layer** that populates the map for that specific encounter. Content elements fall into two orthogonal axes:

**By kind:**
- **Environmental conditions** — scene-level effects that apply to the whole map (silence, fire, darkness, difficult terrain zone)
- **Items** — physical objects placed on the map
- **Creatures** — monsters and NPCs
- **Player characters** — heroes present in this scene

**By interactability:**
- **Decorative** — purely visual; no gameplay consequence (a wall torch, a crumbled pillar, bones on the floor)
- **Interactable** — has gameplay consequence when a player acts on it (loot container, lever, trap, NPC, monster)

This axis is orthogonal to kind: a creature can be decorative (ambient villager) or interactable (quest-giver, combatant). An item can be decorative (scattered coins as flavor) or interactable (a chest with loot).

Current data model conflates these: the `entities` table holds both interactable objects and monsters and heroes, using `type` and `tags` to distinguish them. Tile `decoration` (issue #125) is purely decorative but lives on the tile, not in a content layer. There is no concept of environmental conditions as a scene-level property.

---

## Open Questions

**Campaign / map / scene structure:**

- **Q1** — Does a campaign hold multiple maps? If yes, are maps sequential (one active at a time) or can multiple be simultaneously running (parallel encounters)?
- **Q2** — Is a scene a persistent DB concept (authored ahead of time, reusable across campaigns) or ephemeral (runtime only, born when the DM activates a map)?
- **Q3** — If a `maps` and/or `scenes` layer is introduced, what moves out of `campaigns`? (`map_width`, `map_height`, `tile_size`, `grid_tiles`, `entities` — all candidates)
- **Q4** — Does `SceneServer` become one server per scene, or one server per campaign holding one active scene at a time?

**Scene content layer:**

- **Q5** — Should environmental conditions (silence, fire, darkness) be a property of the scene record, or modelled as `ActiveEffect` entries in `Engine.State` (the existing planned field)?
- **Q6** — Is the decorative/interactable distinction a flag on the entity (`interactable: boolean`), or should purely decorative elements be tile-layer data (like the existing `decoration` field on `GridTile`) and interactable elements always be entities?
- **Q7** — How does the content layer relate to map authoring? Is content authored per-scene (a scene template with a monster set and item placement), or per-campaign-session (the DM places content live at the table)?

**Scope:**

- **Q8** — Which in-flight issues (#121–#128, #125) are blocked by this restructure, and which survive it unchanged?
- **Q9** — Is introducing a full `maps`/`scenes` layer in scope now, or do we document the single-map constraint, defer, and proceed with in-flight work?

---

## Reference model: map editors (SC2 / AoE2) — and where the analogy breaks

RTS map editors (StarCraft 2, Age of Empires 2) got the map/scenario/campaign separation right:

- **Map** — tile grid, terrain, static decoration (reusable, purely spatial)
- **Scenario** — map + content layer: unit placements, item placement, environmental conditions, win conditions
- **Campaign** — ordered sequence of scenarios with narrative connective tissue

The trigger system is the relevant mechanism for the content layer: rather than baking interactable behaviour into tile types, SC2/AoE2 attach *trigger rules* to scenarios ("if unit enters region X → apply effect Y"). This is the right structural instinct for environmental conditions and interactable objects.

**Where the analogy breaks — context-sensitive evaluation:**

SC2/AoE2 triggers are largely context-free: "unit enters region → spawn units" is deterministic regardless of who the unit is or what happened before. D&D interactions are not. The same action on the same entity produces different outcomes depending on:

- **Entity context** — the tiger's `disposition` in its `stats` JSONB (base behaviour as authored)
- **Campaign context** — the DM may override the tiger's disposition for this specific campaign ("friendly tiger" variant), independently of the entity's base state
- **Actor context** — the acting player's proficiencies and abilities affect the outcome (Animal Handling check changes the odds)
- **Scene context** — active environmental conditions may modify the interaction

In our event model this maps correctly: the `:pet_animal` command issues a generic event; the engine evaluates predicates against entity state, campaign overrides, actor stats, and active scene effects to determine the effect. The outcome is not authored as a static trigger rule in the scenario — it is resolved at runtime by the predicate/modifier pipeline.

**Implication for the content layer:** "interactable" does not mean "carries a hardcoded trigger." It means the entity **participates in the event pipeline** — the engine dispatches events to it and the predicate system resolves outcomes using the full context stack. Campaign-level DM customisation (the friendly tiger) is a **campaign-scoped entity override** (a modifier or a stats override), not a scenario trigger. This connects to the deferred DM override issue #32.

---

## Design Options

### Option A — Stay flat (single map per campaign, documented constraint)

Keep the current schema. Document "one campaign = one map" as a deliberate simplification. Defer multi-map support to a future brainstorm. All in-flight WP-F/K/L/M work proceeds unchanged.

Trade-offs:
- `+` No schema churn now; in-flight issues unblocked immediately
- `+` Simpler `SceneServer` lifetime (campaign start → campaign end)
- `−` Future multi-map support requires a larger migration touching tiles, entities, and SceneServer
- `−` The name "campaign" sets an expectation of multiple encounters that the data model won't meet

### Option B — Introduce a `maps` table now, keep scenes ephemeral

Add a `maps` table between `campaigns` and tiles/entities. A "scene" is just the running `SceneServer` for a given map — ephemeral, no new DB table. `grid_tiles` and `entities` belong to a map, not a campaign. One map is "active" per campaign at a time.

Trade-offs:
- `+` Aligns the schema with the domain; easier multi-map expansion later
- `+` `SceneServer` keyed by `map_id` is cleaner (a map has one canonical scene)
- `−` All in-flight WP-F/K/L/M issues need their FK references updated before starting
- `−` Significant migration work before any gameplay feature lands

### Option C — Introduce `maps` but keep campaign-scoped SceneServer

Add a `maps` table for persistence, but keep `SceneServer` keyed by `campaign_id`, holding one active map at a time. Switching maps = loading a new map into the same server.

Trade-offs:
- `+` Separates persistence concern (maps table) from runtime concern (server lifetime)
- `+` Players don't need to reconnect when the active map changes
- `−` More complex server state (needs an `active_map_id` field and map-switch logic)
- `−` Still requires updating FK references for all in-flight issues

---

## Tile strata

All possible layers at a world coordinate `(x, y)`:

| Stratum | Examples | Home | Event pipeline |
|---|---|---|---|
| **Terrain** | grass, stone, sand, water | `GridTile` (`texture`, `movement` JSONB) | No |
| **Tile decoration** | bones, grass tuft, crack in floor | `GridTile.decoration` (string key into `Data.Environment`) | No |
| **Structure** | wall, pillar, doorway, altar, ruin | entity `type: "structure"`, tags `["blocking"]` | Rarely (destructible) |
| **Object** | chest, lever, trap, well | entity `type: "object"`, tags `["interactable"]` | Yes |
| **Creature / NPC** | goblin, villager, quest-giver | entity `type: "monster"` | Yes |
| **Hero** | player character | entity `type: "hero"` | Yes |
| **Spatial effect** | fog zone, fire pool, silence field | scene `active_effects` with spatial extent (`tiles: [{x,y}]` or `radius`) | Yes |
| **UI overlay** | valid move highlight, FOW mask, selection ring | render only — no data layer | — |

**Decoration / structure boundary:** if it affects pathfinding or can be targeted by the event pipeline → entity. If purely cosmetic and single-tile → tile decoration.

**Structure type gap:** current `type` enum is `"hero" | "monster" | "object"`. `"structure"` needs adding, or structures use `type: "object"` with a `["structure", "blocking"]` tag set.

---

## Tile movement permissions

`walkable: boolean` is insufficient. A tile with a boulder is not walkable but may be climbable. Movement is a set of permitted modes, each with a cost:

```elixir
# GridTile.movement — JSONB, replaces walkable: boolean
%{
  "walk"  => "normal" | "difficult" | "blocked",
  "climb" => "normal" | "difficult" | "blocked",
  "swim"  => "normal" | "difficult" | "blocked",
  "fly"   => "normal" | "difficult" | "blocked"
}
# Absent key = :blocked. Defaults: open ground = %{"walk" => "normal", "fly" => "normal"}
```

**Entity movement attributes** are the matching half. Currently `stats` only carries `"speed"` (walk). A full movement model requires:

```elixir
# In entity stats JSONB
"speed"        => integer   # walk speed in feet
"climb_speed"  => integer | nil
"swim_speed"   => integer | nil
"fly_speed"    => integer | nil
```

**Engine implications:**

- `valid_moves` computation must check tile permitted modes against entity available modes, deducting from `movement_remaining` at the appropriate cost multiplier
- `action_economy.movement_remaining` (planned in #37) needs to track remaining movement per mode, or a single pool with mode-aware cost deduction
- `RuleModifier` entries affect both sides: Fly spell grants `fly_speed`; Restrained sets all movement to 0; Spider Climb grants `climb: :normal` on any surface regardless of tile permission

This is a cross-cutting constraint: `GridTile.movement`, entity `stats` movement keys, `valid_moves` computation, and the `RuleModifier` pipeline must be designed together. Affects issues #37 (entity map extensions) and the planned `DnD5e.Stats` module (#38).

---

## Environment content — design implications for BS-17

The content layer must accommodate multiple categories of environmental element. Three constraints that affect the structural decisions here:

- **Atom enum won't scale.** The current `GridTile.decoration` field is `atom | nil` with three hardcoded values (issue #125). A fat environment catalogue requires a string key into a `Data.Environment` catalogue module — this affects Q6.
- **Multi-tile structures need a separate representation.** A building footprint or large statue cannot live on a single tile's decoration field. Either multi-tile entities or a dedicated structures layer is needed — this affects Q3 and Q6.
- **Atmosphere markers are not tile data.** Fire, fog, magical silence are scene-level effects, not properties of individual tiles — this reinforces Q5.

---

## Relationship to #85 — Content Creation Tools

The DM campaign authoring surface (map editor, scene composition, entity placement, campaign sequencing, DM overrides) is part of the broader **content creation tools** scope already captured in issue [#85](../issues/085-content-creation-tools-design.md).

**#85 is currently deferred.** Its unpark condition ("admin app foundation stable") is now met (WP-E closed #64–#69). However, the structural decisions in this brainstorm are a **prerequisite** for the map module editor. #85's brainstorm cannot be productively opened until BS-17 is settled.

**Scope boundary:** authoring tool questions belong in #85's brainstorm, not here.

---

## Captured for later

_Ideas surfaced during exploration that don't belong in BS-17's settlement. Carry these forward to the appropriate brainstorm or issue when BS-17 closes._

- **Fat environment seed collection** — tile textures (grass, stone, dirt, sand, water, wood planks, snow, lava), decorative elements (rocks, shrubs, mushrooms, bones, torch, barrel, crate), structures/remains (ruined wall, doorway, pillar, altar, well, statue), atmosphere markers (fog, fire, magical glow). Will need its own `Data.Environment` catalogue module and seed data. Distinct from the items catalogue in #120. Prerequisite for the #85 authoring tool.

- **DM campaign authoring sub-application** — map editor, scene composition, entity/item/condition placement, campaign sequencing, DM entity overrides. Part of the #85 content creation tools scope. Unpark #85 once BS-17 closes.

- **Appearance editor** — per-element SVG visual customisation: shape parameters, colour palette, size variants for tile textures, decorative elements, and structures. Sub-application within #85's editor suite; uses live SVG preview rendering.

- **Campaign-scoped entity overrides** — e.g. the "friendly tiger" — a DM sets a disposition override for a specific entity in a specific campaign, independent of the entity's base state. Connects to deferred issue #32 (DM override event schema). Needs a data model slot (campaign-scoped modifier set or stats override table).

- **Issues #37 and #38 need updating for multi-mode movement** — both were written when `walkable: boolean` was the model. #37 (entity map extensions) plans `action_economy.movement_remaining` as a single integer; it needs to accommodate per-mode movement or a mode-aware cost deduction. #38 (`DnD5e.Stats`) needs to compute from `climb_speed`, `swim_speed`, `fly_speed` entity stats. Revisit both when BS-17 triages.

- **Trap mechanism model** — a trap entity has three distinct concerns: sensor (trigger zone + condition: on_enter, on_interact, on_weight), mechanism (effect payload), and target(s) (`linked_entities` — may be remote, e.g. closing a door elsewhere on the map). Armed/visible state on the entity. Tile is unchanged by trap presence. A triggered trap that reveals a hole replaces itself with a pit object entity rather than mutating the tile. Design of the mechanism payload and `linked_entities` schema belongs in the #85 authoring tool brainstorm.

- **Traversable holes and vertical transitions** — a pit, trapdoor, rope bridge, or ladder is a door-like object entity whose `stats["movement"]` defines how it is traversable (climb, walk, fly) and whose mechanism payload can dispatch a `:scene_transition` event to a destination map coordinate. This is the natural vertical analogue of a door and previews the multi-map transition model from Q1.

---

## Decisions

| Q | Decision | Deferred? |
|---|---|---|
| **Q1** | Sequential multi-map campaigns; one active map per campaign at a time. Parallel encounters (split party) left as a future extension — handled narratively in D&D as separate turns, not requiring simultaneous server instances now. | No |
| **Q2** | Scene is a persistent DB concept (scene template). A template is reusable across campaigns; campaign-specific PC actors are not part of the template. Runtime instance is `Engine.State` only. Schema: `scene_templates` (map_id, placements JSONB, starting_conditions JSONB, owner_user_id, visibility) + `campaign_scenes` (campaign_id, scene_template_id, sequence_order, overrides JSONB). | Phase 2 |
| **Q3** | `x_extent` / `y_extent` (world-axis coordinates, rotation-proof). `z_extent` reserved for future vertical axis. These fields, plus `tile_size`, move from `campaigns` to a new `maps` table. `map_width` / `map_height` / `map_depth` are rejected as viewer-relative. | No |
| **Q4** | `SceneServer` keyed by `campaign_id`, holding one active map at a time (Option C). Switching maps = loading new map into the same server. Players do not reconnect on map switch. | No |
| **Q5** | Environmental conditions are `active_effects` entries in `Engine.State` with spatial extent — not a column on the scene record. Scene template's `starting_conditions` JSONB seeds them at scene start. | No |
| **Q6** | Purely cosmetic single-tile elements → tile decoration field. Anything with state, lifecycle, or event participation → entity. Strata table (8 layers) confirmed as the complete enumeration. Structures and objects carry `stats["movement"]` JSONB — these overlay the tile's movement at runtime; the tile itself does not change. The tile/entity separation rule: if it has state, lifecycle, or event participation → entity; if it is the ground itself → tile. | No |
| **Q7** | Content is authored offline as a scene template (persistent DB). Runtime mutations (DM places a crate mid-session) are stored under the campaign run as overrides, not baked into the template. | No |
| **Q8** | All WP-F/K/L/M in-flight issues (#121–#128, #125) survive the restructure unchanged. Phase 1 (maps table migration) is a prerequisite only for new scene/map features, not for any currently active work package. | No |
| **Q9** | Phase 1 now: `maps` table + `x_extent`/`y_extent` + `grid_tiles` FK change + `GridTile.movement` JSONB replacing `walkable: boolean`. Phase 2 deferred until after #85: `scenes`/`scene_templates` tables, scene-scoped entities, `starting_conditions`. | Phase 2 deferred |

**Movement model supplement (settled during this session):**

- `valid_moves` merges movement at two layers: `effective_permission(x,y,mode) = min(tile.movement[mode], min(entity.stats["movement"][mode] for each entity at (x,y)))`. Absent key = blocked. Applies uniformly to structures, objects, traps — any entity that physically occupies a tile.
- Traps: all trap-specific attributes (armed, visible, trigger_condition, mechanism, linked_entities) live on the entity. The tile underneath is unchanged. A trap that reveals a hole on trigger replaces itself with a "pit" object entity rather than mutating the tile's terrain.
- Traversable holes, trapdoors, rope bridges: modelled as door-like object entities with `stats["movement"]` defining traversal modes. Their mechanism payload can dispatch a `:scene_transition` event (future multi-map use).

---

## Issues to Open

Three issues extracted from Phase 1 decisions. Phase 2 issues (scenes/scene_templates tables) are deferred until #85 brainstorm.

### [#129](../issues/129-maps-table-phase-1-migration.md) — Phase 1: introduce `maps` table
**Tags:** architecture, ops  
**Priority:** medium

- New `maps` table: `id`, `campaign_id` FK, `x_extent` integer, `y_extent` integer, `tile_size` integer, timestamps
- Migrate geometry columns out of `campaigns` (`map_width`, `map_height`, `tile_size` → `maps`)
- Change `grid_tiles.campaign_id` FK → `grid_tiles.map_id`
- Add `active_map_id` FK on `campaigns` (the currently loaded map)
- Update `Engine.State` to carry `map_id`
- Update `SceneServer` to load/switch maps via `map_id`
- Update seeds, fixtures, and data model doc

### [#130](../issues/130-grid-tile-movement-jsonb.md) — Phase 1: `GridTile.movement` JSONB (replaces `walkable: boolean`)
**Tags:** architecture, gameplay  
**Priority:** medium  
**Depends on:** #129 (shares migration batch or follow-on)

- Migration: add `movement` JSONB column to `grid_tiles`, drop `walkable` boolean, backfill defaults (`%{"walk" => "normal", "fly" => "normal"}` for previously walkable tiles; `%{}` for previously non-walkable)
- Update `%GridTile{}` struct and `Engine.State` tile map shape
- Update seeds with explicit movement maps per terrain type
- Update `valid_moves` computation: merge tile movement + all entity `stats["movement"]` at coordinate, per mode
- Entity `stats["movement"]` absent key = blocked; no tile mutation when an entity is placed or removed

### [#131](../issues/131-entity-movement-stats-and-valid-moves.md) — Entity movement stats + `valid_moves` multi-mode deduction
**Tags:** gameplay, rules  
**Priority:** medium  
**Depends on:** #130

- Add `climb_speed`, `swim_speed`, `fly_speed` to entity stats JSONB (integer | nil) in seeds and fixtures
- Update `DnD5e.Stats` (#38) to derive from all four speed keys
- Update `action_economy.movement_remaining` (#37) to support mode-aware cost deduction (difficult = ×2 cost)
- `RuleModifier` entries that grant or remove movement modes (Fly spell, Restrained, Spider Climb) must target the correct stats keys
