# #188 · Walls/doors (`State.edges`) decoded but never enforced in movement

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** bug, architecture, gameplay, rules
**Related:** #157 (tile occupancy model — already scopes edge-model
integration into `effective_traversability`), #156 (coordinate model —
established the edge storage this issue found unused)

`State.edges` is decoded (`Coords.decode_edges/1`) and persisted, but
nothing in the engine reads it. `Rules.valid_moves/3` computes reachability
purely via Chebyshev distance bounded by `max_tiles` and per-tile movement
permission — no wall/door/edge lookup anywhere. Movement is straight-line:
a tile behind a wall is reachable as long as the destination tile itself
is passable, with no pathing around obstacles.

Practical effect: a documented map feature (the Sunken Crypt's door, which
the `verify` skill's own walkthrough advertises) does nothing mechanically
— it renders but doesn't block or gate movement.

**This likely folds into #157**, which already specifies "Edge model
integration: Traversability checks the `edges` map ... for walls/doors on
the path between tiles" as part of its broader occupancy taxonomy work.
Filing this separately only to record the concrete confirmed-dead-code
finding; **do not implement independently — resolve via #157's scope**,
or close this as a duplicate once #157 lands the edge check.

**Acceptance criteria**
- [ ] Confirmed against #157: either this is folded into #157's
      implementation (preferred), or #157 is descoped and this becomes its
      own path-B ticket with actual pathing (not just adjacency-edge
      blocking)
- [ ] Once resolved: a wall/door between two tiles actually blocks/gates
      `valid_moves` output
- [ ] Regression test using a real map fixture with an edge (e.g. a closed
      door) asserting the tile behind it is excluded from `valid_moves`
- [ ] `mix precommit` passes

**Source:** identified via external code review (GLM/ZAI), verified
against code before filing.
