# #183 · Stale roll timers not cancelled on submit

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** bug, architecture, rules

`SceneServer` schedules `{:auto_roll_timeout, entity_id}` /
`{:initiative_timeout, entity_id}` via `Process.send_after/3` (60s) whenever
a roll is opened (attack, spell cast, initiative). No timer ref is ever
stored, so none are cancelled when the player actually submits via
`submit_roll`.

The `{:auto_roll_timeout, ...}` handler's guard is
`if State.awaiting_roll?(state)` — "is *some* roll pending", not "is this
the roll this timer was scheduled for." `pending_roll` stores only
`{:attack, target_id}` / `{:cast_spell, spell_key, target_id}`, with no
binding back to the timer/attacker that opened it. Consequence: a
late-firing stale timer from an earlier attack can fire after a *different*
roll is already pending and auto-resolve that one instead.

`{:initiative_timeout, entity_id}` is comparably safer — its guard is
`MapSet.member?(pending_initiative_rolls, entity_id)`, keyed by entity — but
the timer is still never cancelled, so it's wasted work rather than a
correctness bug on that path.

This is the exact class of bug CLAUDE.md's "handle stale IDs gracefully"
line targets, and the gap traces back to #146 (dice roll prompt +
pending-roll state), which introduced the 60s timeout without an
explicit timer-identity/cancellation design.

**Acceptance criteria**
- [ ] Timer refs are stored (e.g. on `state` or in a small map keyed by
      entity_id/roll)
- [ ] `submit_roll` cancels the timer for the roll it resolves
      (`Process.cancel_timer/1`)
- [ ] `{:auto_roll_timeout, ...}` guard checks that the specific pending
      roll this timer was scheduled for is still the one pending, not just
      "some roll is pending"
- [ ] Regression test: open roll A, let a stale timer for an earlier roll
      fire after roll A is submitted — assert it does not resolve/mutate
      roll A
- [ ] `mix precommit` passes

**Source:** identified via external code review (GLM/ZAI), verified against
code before filing.
