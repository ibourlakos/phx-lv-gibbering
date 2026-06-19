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

## Decisions

| Question | Decision |
|---|---|
| Explicit Move button or toggle? | Explicit button required. Overlay does not appear on entity select. |
| Cost representation? | Colour tint by terrain tier: green (×1), yellow (×2 difficult). No numerical labels on tiles. |
| Unreachable tiles when movement hits zero? | Overlay hides entirely; unreachable tiles are not shown (not greyed out). |
| Economy slot? | No action slot consumed. Movement deducts from `movement_remaining` only on tile click. |
| Live hover or static range? | Static range; hover tooltip shows cost to that tile in feet. No animated path trace. |
| Non-walk modes in scope? | Walk only for v1. Climb/swim/fly deferred. |

## Issues Opened

| Issue | Title | Status |
|---|---|---|
| [#144](../issues/144-movement-confirmation-ui-gate.md) | Movement confirmation UI gate | open (WP-P) |

This brainstorm will be deleted when #144 is closed.
