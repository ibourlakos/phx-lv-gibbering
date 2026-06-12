# #28 · Multi-tile entity footprints in isometric rendering
**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** No large creatures (2×2+) exist in the game yet. All entities are currently 1×1. The depth-sort and movement-distance design questions are real but have no urgency. Un-defer when the first Large creature is added to the content catalogue.
**Priority:** low
**Tags:** discovery, architecture, rendering

Large creatures in D&D 5e occupy more than one tile (Large = 2×2, Huge = 3×3, Gargantuan = 4×4). Isometric depth-sort (painter's algorithm) becomes ambiguous when a single entity spans multiple grid positions.

Open questions:
- Does the entity record a single anchor tile (top-left corner) or a full footprint list?
- How does depth sort handle a sprite that spans tiles occupied by other entities?
- Do movement/attack range calculations use the nearest occupied tile or the anchor?

Currently all entities are 1×1. This is a deferred design problem — no large creatures exist yet.

**Acceptance criteria**
- [ ] Decision written: anchor vs. footprint representation, depth-sort strategy
- [ ] Entity struct and move/attack range calculations updated to support the chosen model
- [ ] At least one 2×2 entity renders and moves correctly on the isometric grid
