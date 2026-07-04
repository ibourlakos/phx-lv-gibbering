# #175 · Campaign join endpoint: malformed id crashes, missing campaign reports success
**Status:** closed
**Opened:** 2026-07-03
**Closed:** 2026-07-04
**Priority:** low
**Tags:** bug, ui

`GibberingTalesWeb.PageController.join/2` has two robustness gaps:

1. `String.to_integer(campaign_id)` raises `ArgumentError` on a non-numeric param —
   `POST /campaigns/abc/join` returns a 500 instead of a 4xx/redirect.
2. The `Campaigns.join_campaign/2` result is ignored. For a nonexistent campaign id the
   insert either raises (FK constraint → 500) or returns an error tuple that is
   discarded — the user sees the "You joined the campaign." flash either way.

**Acceptance criteria**
- [x] Non-numeric campaign id → flash error + redirect (no 500)
- [x] Nonexistent campaign id → flash error + redirect (no 500, no false success)
- [x] `join_campaign/2` returns `{:ok, _} | {:error, _}` and the controller branches on it
- [x] Controller tests cover both failure paths
- [x] `mix precommit` passes
