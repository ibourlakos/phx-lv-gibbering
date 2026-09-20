# #187 · `movement_cost_ft` is dead code — difficult terrain never charged

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** bug, gameplay, rules, architecture

`Rules.movement_cost_ft/2` is defined and unit-tested
(`test/engine/entity_movement_test.exs`) but has zero production callers.
`SceneServer`'s `do_move_entity` charges a flat
`chebyshev(entity.x, entity.y, x, y) * 5` regardless of terrain.
Meanwhile `build_move_costs/2` computes and stores a per-tile
`:normal`/`:difficult` tier (via `Rules.tile_movement_permission/4`) purely
for the move-cost overlay — so the UI visually displays terrain costs the
engine doesn't actually enforce. A player can move through difficult
terrain and only ever pay standard cost.

Two viable resolutions:
1. Wire `movement_cost_ft`/the tile tier into `do_move_entity`'s actual
   cost calculation, so difficult terrain doubles cost as displayed.
2. If flat-cost movement is an intentional simplification for now, delete
   `movement_cost_ft` and the `:difficult` tier computation/overlay so the
   UI stops promising an enforcement that doesn't exist.

Leaning toward (1) since the overlay and tests already assume terrain cost
is a real mechanic, but flag for a decision before implementation.

**Acceptance criteria**
- [ ] Decision recorded: enforce difficult-terrain cost, or remove the
      unenforced display
- [ ] If enforcing: `do_move_entity` cost calculation charges the tiered
      cost per tile crossed, not flat `chebyshev * 5`
- [ ] Regression test: moving through a tile flagged `:difficult` costs
      more feet than an equivalent move through `:normal` tiles
- [ ] `mix precommit` passes

**Source:** identified via external code review (GLM/ZAI), verified
against code before filing.
