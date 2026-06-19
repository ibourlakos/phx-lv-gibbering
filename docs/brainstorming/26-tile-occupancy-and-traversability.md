# Brainstorm #26 — Tile occupancy and traversability

**Status:** open

## Context

The current model treats traversability (walkable / not) as a tile property.
This breaks down as soon as tiles have dynamic content: a movable rock blocks
movement while present and stops blocking when thrown. We need a richer occupancy
model and a computed traversability function.

## Occupancy taxonomy

Everything that can reside on a tile falls into one of five categories:

| Category | Examples | Movable | Has game coord | Affects traversal |
|---|---|---|---|---|
| **Terrain** | Grass, lava, water, ice | No | Tile itself | Base cost/block |
| **Objects** | Rock, barrel, crate, door | Some | Tile (integer) | Via `movement_modifier` |
| **Items** | Coin, potion, thrown stone | Yes (to inventory) | Tile (integer) | No |
| **Effects** | Grease patch, spike growth zone, ice slick from flask | No (area-bound) | Tile (integer), duration | Via `movement_modifier` |
| **Entities** | Creatures, PCs, NPCs | Yes (self-moving) | Tile (integer) | Blocks unless ally |

"Occupants" is the collective term for everything in categories 2–5 on a tile.

### The Effects category

Effects are the key addition not present in the current model:
- No physical form — cannot be picked up or moved by entities
- Tied to a tile or area with a duration and/or a source (caster concentration)
- Created by spells (Web, Spike Growth, Grease), item use (oil flask), or
  environmental events
- Removed when duration expires, concentration drops, or the source is destroyed
- May stack with terrain modifiers (ice terrain + Grease effect = two sources
  of difficult terrain, but policy is: difficult terrain does not stack — always 2×)

### Edge occupants (walls and doors)

Walls and closed doors occupy the **edge between two tiles**, not a tile center.
This requires an edge model alongside the tile model:
- Each tile has four edges (N, S, E, W)
- An edge can have a wall, a door (open/closed), or nothing
- A wall blocks movement and line of sight across that edge
- A door blocks when closed, passes when open
- Half-walls block line of sight partially but not movement

## Traversability is computed, not stored

`effective_traversability(tile, mover)` is a function, not a field.

Inputs:
1. **Terrain base** — intrinsic cost/block from terrain type (lava = impassable,
   shallow water = swimming, ice = difficult terrain + slip hazard trigger)
2. **Object modifiers** — any object with `blocks_movement: true` → impassable;
   `difficult_terrain: true` → 2× cost
3. **Effect modifiers** — same as object modifiers but from effects layer
4. **Entity occupancy** — entity present → impassable, unless mover and occupant
   are allies (D&D 5e: you may pass through an ally's space)
5. **Mover's movement mode** — walk, fly, swim, burrow, ethereal each have
   different sensitivity to the above:
   - Fly ignores ground-level objects and effects
   - Burrow ignores surface objects and entities
   - Ethereal ignores all physical occupants
   - Swim ignores surface difficult terrain but has its own cost on water tiles

### The ally exception

Traversability is **relative to the moving entity**. Two callers querying the same
tile get different answers if one is an ally and one is an enemy of the occupant.

### Cover without blocking

Some objects (low wall, pillar, barrel) have `blocks_movement: false` but
`cover: :half | :three_quarters | :full`. The traversability function returns
walkable, but the line-of-sight function uses the cover value separately.

## Lifecycle transitions

### Dead creature → object

When an entity reaches 0 HP and dies, it transitions from the Entities category
to the Objects category as a corpse. The corpse:
- Imposes difficult terrain on its tile (clambering over a body)
- Does not fully block movement
- Is lootable (has an inventory that transfers to Items on the tile when looted)

The engine needs a defined death transition: `Entity → Corpse (Object)`.

### Item consumed into effect

When an oil flask is poured on a tile, the Item is removed from inventory and
an Effect (oil slick) is created on the tile. The item and the effect are
different occupancy categories; the transition is explicit.

## Canonical test case: the ice slip scenario

Ice as an effect (or terrain type) requires:
1. Tile/area marked with `slip_hazard: true`
2. An **entry trigger** that fires when an entity moves onto the tile
3. A Dexterity saving throw (DC configurable)
4. On failure: apply `prone` condition to the entity

This is the simplest possible trigger chain: `enter tile → roll save → apply condition`.
Any trigger infrastructure built for ice handles caltrops, Spike Growth damage
on entry, alarm spells, and pressure plates.

The ice slip scenario is the minimum viable test for the entry trigger system.

## Open questions

- Difficult terrain stacking policy: D&D RAW says no stacking (always 2×).
  Do we enforce this at the engine level or allow homebrew override?
- How are edge occupants (walls, doors) stored? As a separate edges table/map
  keyed by `{tile_coord, direction}`, or as attributes of the tile itself?
- Entry triggers: should they be stored as part of the Effect occupant, or as
  a separate trigger system the Effect registers with?
- Can a single tile have multiple effects simultaneously? (Web + darkness +
  spike growth?) If so, how are their modifiers composed?
- How does the corpse transition interact with resurrection spells? Does the
  entity record survive in a `dead` state, or is the corpse a fully new object?

## Cross-references

- Related: brainstorm #25 (elevation — traversability must account for elevation
  transitions between tiles)
- Related: brainstorm #27 (coordinate model — traversability queries reference
  spatial addresses, not just (x,y))
- Related: brainstorm #21 (movement overlay — the overlay visualises
  effective_traversability output per tile)
- Related: issue #135 (inspection panel — clicking a tile with effects should
  show effect details in the panel)
