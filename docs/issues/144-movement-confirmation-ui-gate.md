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

## Settled decisions from BS-21

- **Overlay trigger:** explicit Move button required. Overlay does not appear on entity select.
- **Cost representation:** colour tint by terrain tier — green (×1 normal), yellow (×2 difficult), no tile shown for impassable. No numerical labels on tiles; cost shown only in hover tooltip.
- **Zero-movement state:** when `movement_remaining == 0`, overlay hides entirely and Move button is disabled. A visual indicator appears on the entity token (consistent with the condition icon system used for prone/blind/deafened) to signal movement is exhausted for this turn. The Move button label may also reflect "0 ft remaining" as secondary feedback.
- **Economy:** movement costs `movement_remaining` only — no action/bonus action slot consumed. Move button gates the UI; actual deduction on tile click.
- **Hover behaviour:** static reachable range; hover tooltip shows path cost to that tile in feet. No animated path trace on hover (v1).
- **Movement modes:** walk mode only. Climb/swim/fly deferred.

**Acceptance criteria**
- [ ] Activating move action shows coloured reachable tile overlay
- [ ] Hover tooltip shows path cost in feet
- [ ] Clicking a reachable tile commits the move and refreshes overlay
- [ ] Escape / clicking non-reachable tile cancels without consuming movement
- [ ] Move button disabled when `movement_remaining == 0`
- [ ] A movement-exhausted indicator appears on the entity token when `movement_remaining == 0` (same icon layer as condition badges for prone/blind/deafened)
- [ ] `mix precommit` passes
