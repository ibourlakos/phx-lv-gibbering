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

## Issues to Open

*(populated after settlement)*
