# #161 · Freeform dice tray — player-initiated multi-die roll
**Status:** closed
**Opened:** 2026-06-23
**Closed:** 2026-06-23
**Priority:** low
**Tags:** gameplay, ui, rendering

Players can currently only roll dice when the engine demands it (attack, initiative,
saving throws). This issue adds a persistent freeform tray in the player panel that
lets players throw any combination of standard dice at any time, for any reason.

Design settled in brainstorm #31.

**Scope:**
- Click-to-increment die picker (d4, d6, d8, d10, d12, d20, d100) with Clear + Roll
- `handle_event("freeform_roll", …)` in GameLive — results generated server-side, no
  SceneServer involvement
- Sequential stagger animation (reuses existing `push_event("roll_dice", …)`) capped
  at 3 die animations; remaining dice noted in label
- Result appended to event feed: `"<name> rolled 2d6 + 1d20 → [3, 5] + [17] = 25"`
- Always public (all players + DM see it)
- DM does not see the tray (DM panel is separate)

**Out of scope:** flat modifier input, private rolls, per-roll-type labels, DM freeform
tray (separate concern).

**Acceptance criteria**
- [x] Die picker renders in player panel with all 7 die types; counts update on click
- [x] Roll button disabled when no dice selected
- [x] Clear resets all counts
- [x] Server generates results for all selected dice and broadcasts `FreeformRoll` event
- [x] Roll animation fires (sequential stagger, ≤3 dice animated)
- [x] Event feed shows full expression, individual results, and total
- [x] `mix precommit` passes
