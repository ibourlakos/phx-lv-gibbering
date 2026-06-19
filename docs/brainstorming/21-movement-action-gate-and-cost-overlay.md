# Brainstorm #21 — Movement action gate and cost-coloured overlay

**Status:** open

## Context

Currently the movement overlay (reachable-tile highlight) appears as soon
as the active entity is selected, before the player has expressed intent
to move. This has two problems:

1. **Visual clutter** — the full blue grid floods the map every time you
   click a character, even when you intend to cast a spell or attack.
2. **No cost feedback** — all reachable tiles look identical; terrain with
   higher movement cost (e.g. a climbable rock, difficult ground) is
   indistinguishable from free movement.

## Open questions

- Should movement require an explicit "Move" action button press before
  the overlay appears? Or should there be a toggle (always-on vs. on-demand)?

- How do we represent movement cost visually? Options:
  - Colour gradient (green → yellow → red by remaining movement after step)
  - Percentage label on each tile
  - Tile tint keyed to cost tier (×1, ×2, impassable)

- When remaining movement hits zero mid-overlay, should unreachable tiles
  grey out in place or disappear?

- Does the "Move" action consume from action economy (bonus action / action /
  free), or does it gate the overlay without consuming economy until the
  player commits by clicking a tile?

- Should the overlay update live as the player hovers over tiles (showing
  the path cost to that tile), or only show static reachable range?

- Scope: does this brainstorm also cover non-walk movement modes
  (climb, swim, fly) that have different cost multipliers, or is that
  deferred until those modes are needed?

## Cross-references

- Related: issue #132 (appearance catalogue — tile textures for terrain types)
- Related: future difficult-terrain / elevation work (no issue yet)
