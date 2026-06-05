# #58 · Point buy ability score method
**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** Standard array ships first as the only method in character creation (#52). Point buy adds UI complexity (budget counter, per-score cost table) without blocking the core flow.
**Priority:** low
**Tags:** gameplay, rules

Add point buy as an alternative ability score assignment method in the character creation modal (step 3). The player has 27 points to spend. Each score costs a fixed amount: 8 (0), 9 (1), 10 (2), 11 (3), 12 (4), 13 (5), 14 (7), 15 (9). No score below 8 or above 15 before racial bonuses.

The UI shows a running point budget and per-score +/− controls. The existing standard array method remains the default.

**Acceptance criteria**
- [ ] Method selector in step 3 of the creation modal: Standard Array / Point Buy
- [ ] Point buy UI shows budget remaining and per-score controls
- [ ] Enforces min 8, max 15, budget 27
- [ ] Both methods produce the same six-integer result stored on `Character`
- [ ] `mix precommit` passes
