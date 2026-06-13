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

## Open Questions

- **Q1** — Does a campaign hold multiple maps? If yes, are maps sequential (one active at a time) or can multiple be simultaneously running (parallel encounters)?
- **Q2** — What is a "scene" vs. a "map"? Is a scene an instance of running a map (ephemeral, in-memory only), or is it a persistent concept?
- **Q3** — If a maps layer is introduced, what moves to a `maps` table and what stays on `campaigns`? (`map_width`, `map_height`, `tile_size`, `grid_tiles`, `entities` — all candidates)
- **Q4** — Does `SceneServer` become one server per map, or one server per campaign holding multiple map states?
- **Q5** — Which in-flight issues (#121–#128, #125) are blocked by this restructure, and which survive it unchanged? (Tile `decoration` field, for example, lives on the tile row — it may not care which table owns the FK.)
- **Q6** — Is this restructure in scope for the current project stage, or should we defer multi-map support and explicitly document the single-map limitation as an intentional constraint?

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
