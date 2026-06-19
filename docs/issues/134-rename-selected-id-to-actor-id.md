# #134 · Rename `selected_id` → `actor_id`; introduce `panel_subject` socket assign

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-19
**Priority:** medium
**Tags:** architecture, ui

`selected_id` conflates two concerns: "entity currently taking a combat action" and
"thing the player has clicked to inspect". Brainstorm #18 resolved the naming:

- `selected_id` (GameServer / Engine.State) → **`actor_id`** — the entity whose
  combat turn is active or who has been selected to act
- `inspected` (socket assign, if it exists) → **`panel_subject`** — display-only
  socket assign introduced in issue #135; not renamed here, just establishing the
  canonical name

This issue covers only the mechanical rename of `selected_id` → `actor_id` across
all call sites: GameServer state, Engine.State struct, LiveView assigns, templates,
event handlers, and tests. No behaviour change.

**Acceptance criteria**
- [ ] `Engine.State` field renamed: `selected_id` → `actor_id`
- [ ] `GameServer` renamed throughout: state key, all `handle_call/cast` clauses
- [ ] `GameLive` socket assign renamed; all template references updated
- [ ] All event handler clauses (`select_entity`, `move`, `attack`, etc.) updated
- [ ] All tests updated; `mix precommit` exits 0
- [ ] No references to `selected_id` remain in `lib/` or `test/`
