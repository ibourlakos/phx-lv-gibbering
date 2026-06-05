# #7 · Movement distance algorithm is wrong for D&D 5e

**Status:** closed
**Opened:** 2026-06-04
**Closed:** 2026-06-05
**Priority:** high
**Tags:** bug, rules, gameplay

`calculate_valid_moves` (brainstorm `01` and confirmed in the v0 prototype) uses Manhattan distance, which penalises diagonals at cost 2. D&D 5e core rules treat diagonal movement at equal cost to orthogonal movement (1 square), producing an octagonal movement range — not a diamond. The optional variant rule (DMG) alternates 1-then-2 cost for diagonals.

Current result: a hero with 30 ft (6-tile) speed cannot reach the tile that is 4 squares north and 4 squares east (Manhattan cost = 8), even though it is geometrically reachable under 5e rules (Chebyshev cost = 4, well within range).

The fix is to replace Manhattan distance with Chebyshev distance: `max(abs(dx), abs(dy))`.

**Acceptance criteria**
- [x] `calculate_valid_moves` uses Chebyshev distance (or exposes a ruleset-configurable distance function)
- [x] Proving Grounds shows a correct octagonal movement highlight for a 6-tile-speed hero
- [x] Unit tests cover diagonal vs orthogonal cost equivalence and the boundary edges
