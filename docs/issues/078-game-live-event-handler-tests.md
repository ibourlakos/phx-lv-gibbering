# #78 · GameLive event handler integration tests
**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** gameplay, architecture

`GibberingWeb.GameLive` sits at 26% coverage. The mount path is tested; the event handlers are not. Each handler requires a running `GameServer` backed by a persisted campaign with at least one entity.

Untested handlers (non-exhaustive):
- `handle_event("move", ...)` — issues a move command to `GameServer`
- `handle_event("select_entity", ...)` — updates selected entity in socket assigns
- `handle_event("end_turn", ...)` — triggers `advance_turn` via `GameServer`
- `handle_info` subscriptions — PubSub broadcasts from `GameServer` updating live assigns

**Depends on:** WP-D (#54, #55, #56) — `CampaignCharacter` schema and the entity merge pipeline must exist before campaigns can be seeded with live entities.

**Acceptance criteria**
- [ ] Each major `handle_event` clause has at least one happy-path test
- [ ] PubSub broadcast → socket assign update is tested for at least one event type
- [ ] Tests use `ConnCase` with a DB-backed campaign fixture and a started `GameServer`
- [ ] Coverage on `GibberingWeb.GameLive` reaches ≥ 70%
