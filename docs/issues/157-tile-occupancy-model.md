# #157 · Tile occupancy model — 5-category taxonomy, traversability function, entry triggers
**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** architecture, gameplay, rules
**Depends on:** #156 (coordinate model — edge storage uses normalised edge keys)

Implement the rich occupancy model from brainstorm #26. Replaces the current
`walkable: boolean` on tiles (which was replaced by `movement` JSONB in #130)
with a full 5-category occupancy taxonomy and a computed traversability function.

**Occupancy taxonomy:**
- `Terrain` — tile intrinsic (from `GridTile.movement` JSONB, already in place)
- `Objects` — entities with `type: "object"` contributing `movement_modifier`
- `Items` — on-tile items (do not affect traversability)
- `Effects` — area spell/environmental effects with `movement_modifier` + optional `trigger`
- `Entities` — creatures and PCs (block unless ally)

**Traversability function:**
```elixir
Rules.effective_traversability(state, {x, y, elevation}, mover_entity_id, mode)
# → :blocked | {:cost, multiplier}
```
Inputs: terrain base, object modifiers, effect modifiers, entity occupancy (ally exception), mover's movement mode.
Difficult terrain: no stacking — always 2× regardless of multiple sources (RAW).

**Effects layer in Engine.State:**
- `effects: %{ {x, y} => [%Effect{id, movement_modifier, trigger, duration}] }`
- Multiple effects on one tile: most restrictive modifier wins
- Entry trigger stored on Effect: `trigger: %{on_enter: trigger_spec}` (for ice slip, caltrops, Spike Growth, alarm)

**Edge model integration:**
- Traversability checks the `edges` map from #156 for walls/doors on the path between tiles

**Entity death transition:**
- On `HP → 0`: entity gains `state: :dead`; a Corpse Object is added to the tile referencing the original `entity_id`
- Corpse imposes difficult terrain; is lootable; does not block movement

**Canonical test case — ice slip:**
- Ice Effect on tile with `trigger: %{on_enter: {:saving_throw, :dex, dc: 10, on_fail: :prone}}`
- Entity enters tile → trigger fires → saving throw → condition applied on failure

**Acceptance criteria**
- [ ] `Rules.effective_traversability/4` implemented with all 5 occupancy inputs
- [ ] `Engine.State` gains `effects: %{}` field
- [ ] Ice slip effect can be seeded and triggers `prone` condition on failed DEX save
- [ ] Corpse Object created on entity death; imposes difficult terrain
- [ ] Edge blocking (wall/door) prevents movement across edges in traversability
- [ ] Ally exception: entities may pass through ally spaces
- [ ] `mix precommit` passes
