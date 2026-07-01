# #171 · Engine decomposition Phase 2d — Web + Admin app extraction

**Status:** closed
**Opened:** 2026-07-01
**Closed:** 2026-07-01
**Priority:** high
**Tags:** architecture, admin

Move the player/DM Phoenix LiveView into `apps/gibbering_tales_web/` and the admin Phoenix app (controllers, admin context, admin schemas, admin Repo, admin migrations) into `apps/gibbering_tales_admin/`. This completes the umbrella conversion.

Depends on #170.

---

## `gibbering_tales_web` — modules to move

| Current namespace | New namespace |
|---|---|
| `GibberingWeb.Router` | `GibberingTalesWeb.Router` |
| `GibberingWeb.GameLive` | `GibberingTalesWeb.GameLive` |
| `GibberingWeb.LobbyLive` | `GibberingTalesWeb.LobbyLive` |
| `GibberingWeb.CampaignPrepLive` | `GibberingTalesWeb.CampaignPrepLive` |
| `GibberingWeb.DashboardLive` | `GibberingTalesWeb.DashboardLive` |
| `GibberingWeb.InviteLive` | `GibberingTalesWeb.InviteLive` |
| `GibberingWeb.CharactersLive` | `GibberingTalesWeb.CharactersLive` |
| `GibberingWeb.Components.*` | `GibberingTalesWeb.Components.*` |
| `GibberingWeb.Endpoint` | `GibberingTalesWeb.Endpoint` |
| `GibberingWeb.ErrorHTML/JSON` | `GibberingTalesWeb.ErrorHTML/JSON` |
| `GibberingWeb.Layouts` | `GibberingTalesWeb.Layouts` |
| `assets/` (CSS, JS, tailwind config) | `apps/gibbering_tales_web/assets/` |
| `priv/static/` | `apps/gibbering_tales_web/priv/static/` |

`gibbering_tales_web/mix.exs` deps: `{:gibbering_tales, path: "../gibbering_tales"}`, `:phoenix`, `:phoenix_live_view`, `:esbuild`, `:tailwind`, `:bandit`, etc.

## `gibbering_tales_admin` — modules to move

| Current namespace | New namespace |
|---|---|
| `Gibbering.Admin` context | `GibberingTalesAdmin.Admin` |
| `Gibbering.Admin.SupportUser` | `GibberingTalesAdmin.Admin.SupportUser` |
| `Gibbering.Admin.AuditLog` | `GibberingTalesAdmin.Admin.AuditLog` |
| `GibberingWeb` admin controllers | `GibberingTalesAdmin.*` controllers |
| `GibberingWeb.Plugs.RequireSupportUser` | `GibberingTalesAdmin.Plugs.RequireSupportUser` |
| `GibberingWeb` admin LiveViews | `GibberingTalesAdmin.Live.*` |

**Admin Repo:** create `GibberingTalesAdmin.Repo` — second Repo pointing at the same DB.
- `config :gibbering_tales_admin, ecto_repos: [GibberingTalesAdmin.Repo]`
- Admin endpoint on port 4001 with its own `secret_key_base`

**Admin migrations to move:** `create_support_users` and `create_support_audit_logs` move to `apps/gibbering_tales_admin/priv/repo/migrations/`.

**Dual-Repo note:** the admin context currently reads tales schemas (`User`, `Campaign`, `Character`) via `GibberingTales.Repo` and admin schemas via `GibberingTalesAdmin.Repo`. Both are available because `gibbering_tales_admin → gibbering_tales` in the dep graph. Call the right Repo per schema — no cross-Repo queries needed.

`gibbering_tales_admin/mix.exs` deps: `{:gibbering_tales, path: "../gibbering_tales"}`, `:phoenix`, `:phoenix_live_view`, `:phoenix_live_dashboard`, `:esbuild`, `:tailwind`, `:bandit`, etc.

## Test infrastructure split

The current `test/` directory is a monolith. As part of this phase, tests and support modules relocate to their home app:

| Current path | New path | Notes |
|---|---|---|
| `test/gibbering_web/live/` | `apps/gibbering_tales_web/test/live/` | LiveView tests |
| `test/gibbering_web/` (controllers, components) | `apps/gibbering_tales_web/test/` | Web layer tests |
| `test/support/conn_case.ex` | `apps/gibbering_tales_web/test/support/conn_case.ex` | `GibberingTalesWeb.ConnCase` |
| `test/support/svg_assertions.ex` | `apps/gibbering_tales_web/test/support/svg_assertions.ex` | `GibberingTalesWeb.SVGAssertions` |
| Admin controller tests | `apps/gibbering_tales_admin/test/` | |

`GameFixtures` currently mixes pure state building with DB insertion — split it:
- `build_state/1`, `hero_id/0`, `monster_id/0`, `with_entity/3`, `with_tile/3` → `apps/gibbering_engine/test/support/engine_fixtures.ex`
- `insert_campaign/1` and all DB helpers → `apps/gibbering_tales/test/support/tales_fixtures.ex`
- Layer 3 setup helpers (conn building, user login) → `apps/gibbering_tales_web/test/support/`

`Gibbering.DataCase` → `GibberingTales.DataCase` in `apps/gibbering_tales/test/support/`.

`docs/testing.md` must be rewritten in this phase to reflect umbrella-aware paths, the fixture split, and revised `async` guidance (engine tests can always be `async: true`; SceneServer tests no longer require the shared DB sandbox).

## Acceptance criteria

- [ ] `mix compile` inside `apps/gibbering_tales_web/` passes
- [ ] `mix compile` inside `apps/gibbering_tales_admin/` passes
- [ ] `gibbering_tales_web` has **no** reference to any `GibberingTalesAdmin.*` module
- [ ] `GibberingTalesAdmin.Repo` and `GibberingTales.Repo` both run their migrations cleanly via `mix ecto.migrate` from umbrella root
- [ ] All LiveView + admin controller tests pass from umbrella root
- [ ] Smoke tests (`docker compose --profile smoke up`) pass against port 4000
- [ ] `mix precommit` from umbrella root passes
- [ ] Old `lib/gibbering/` and `lib/gibbering_web/` are empty / removed
- [ ] `GameFixtures` is split — engine fixtures in `gibbering_engine`, DB fixtures in `gibbering_tales`
- [ ] `ConnCase` and `SVGAssertions` live in `apps/gibbering_tales_web/test/support/`
- [ ] `docs/testing.md` updated: umbrella file paths, fixture split, revised `async` guidance
