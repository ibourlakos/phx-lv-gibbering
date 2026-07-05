# #170 · Engine decomposition Phase 2c — Tales domain extraction

**Status:** closed
**Opened:** 2026-07-01
**Closed:** 2026-07-01
**Priority:** high
**Tags:** architecture

Move the D&D 5e domain, Ecto Repo, and all non-admin migrations into `apps/gibbering_tales/`. Verify `gibbering_tales` compiles with only `gibbering_engine` as a code dependency (plus Ecto/Postgrex).

Depends on #169. Predecessor to #171.

---

## Modules to move

| Current namespace | New namespace |
|---|---|
| `Gibbering.Repo` | `GibberingTales.Repo` |
| `Gibbering.Rulesets.DnD5e` + sub-modules | `GibberingTales.Rulesets.DnD5e.*` |
| `Gibbering.Catalogue.Monster/Race/Class/Spell` | `GibberingTales.Catalogue.*` |
| `Gibbering.Data.*` | `GibberingTales.Data.*` |
| `Gibbering.Accounts` + `User` schema | `GibberingTales.Accounts.*` |
| `Gibbering.Campaigns` + all Campaign schemas | `GibberingTales.Campaigns.*` / `GibberingTales.Campaign` etc. |
| `Gibbering.Characters` + `Character` schema | `GibberingTales.Characters.*` |
| `Gibbering.Pipeline.LegalGuard` | `GibberingTales.Pipeline.LegalGuard` |
| `Gibbering.Events.DnD5e.*` | `GibberingTales.Events.DnD5e.*` |
| `Gibbering.Events.Notification.*` | `GibberingTales.Events.Notification.*` |
| `Gibbering.Monitoring.CampaignMetricSnapshot` | `GibberingTales.Monitoring.CampaignMetricSnapshot` |

## Migrations to move

All migrations from `priv/repo/migrations/` **except** `create_support_users` and `create_support_audit_logs` move to `apps/gibbering_tales/priv/repo/migrations/`.

`GibberingTales.Repo` config: `ecto_repos: [GibberingTales.Repo]` under `:gibbering_tales` app config.

## Work

- Move modules + rename atoms
- Update all `alias` / `import` references
- Move non-admin migrations; update any hardcoded repo references
- Move domain + integration tests to `apps/gibbering_tales/test/`
- `gibbering_tales/mix.exs` deps: `{:gibbering_engine, path: "../gibbering_engine"}`, `:ecto_sql`, `:postgrex`, `:pbkdf2_elixir`, etc.
- Verify no Phoenix dependency in `gibbering_tales` (Phoenix is for web apps only)
- Fix remaining compilation in `gibbering_tales_web` / `gibbering_tales_admin` (not yet moved)

## Acceptance criteria

- [ ] `mix compile` inside `apps/gibbering_tales/` passes with no Phoenix in dep tree
- [ ] `mix test` inside `apps/gibbering_tales/` passes (DB migrations run correctly)
- [ ] `mix ecto.migrate` from umbrella root runs `GibberingTales.Repo` migrations cleanly
- [ ] `mix test` from umbrella root passes
- [ ] `mix precommit` from umbrella root passes
- [ ] No Phoenix module references appear in `apps/gibbering_tales/lib/`
