# #144 · Movement confirmation UI gate

**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** ui, gameplay, rendering

## Context

Derived from brainstorm #21 (movement action gate + cost overlay).

The movement overlay already shows reachable tiles, but movement appears to commit
immediately on tile click with no preview or confirmation step. For a minimum
playable loop, players need feedback on how much movement each step costs before
committing.

## What needs to happen

1. When a player activates their movement action (clicks "Move" in the action bar):
   - Highlight reachable tiles coloured by remaining movement cost (green = cheap,
     yellow = up to half movement, red = near limit). Tiles beyond movement budget
     are not selectable.
2. Hovering a reachable tile shows a small tooltip with the path cost in feet.
3. Clicking a tile commits the move (single step) and consumes the appropriate
   movement from `action_economy.movement_remaining`. The overlay refreshes with
   the updated budget.
4. Clicking a non-reachable tile or pressing Escape cancels the move action
   selection without consuming movement.
5. If all movement is spent, the overlay hides and the Move button is disabled for
   the rest of the turn.

## Notes

- This is the minimum viable version from brainstorm #21 — single-step commit,
  no path-planning drag. Multi-step path preview is explicitly deferred.
- Reachable tile computation is already implemented in `Rules.valid_moves/3`; this
  issue is UI-only.

**Acceptance criteria**
- [ ] Activating move action shows coloured reachable tile overlay
- [ ] Hover tooltip shows path cost in feet
- [ ] Clicking a reachable tile commits the move and refreshes overlay
- [ ] Escape / clicking non-reachable tile cancels without consuming movement
- [ ] Move button disabled when `movement_remaining == 0`
- [ ] `mix precommit` passes
