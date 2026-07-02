# #167 · Engine decomposition Phase 2 — Umbrella conversion discovery

**Status:** closed
**Opened:** 2026-07-01
**Closed:** 2026-07-01
**Priority:** high
**Tags:** architecture, discovery, ops

Scope and de-risk the Phase 2 umbrella conversion before committing to implementation issues. Phase 0 (#162) and Phase 1 (#163) are complete. The target structure is decided; the questions below must be answered before implementation can be safely sequenced.

See [engine-decomposition.md](../architecture/engine-decomposition.md) for the decided 4-app structure and Phase 2 migration steps.

---

## Target structure (decided)

```
gibbering_umbrella/
  apps/
    gibbering_engine/        ← GibberingEngine — pure Elixir/OTP, no Phoenix, no Ecto
    gibbering_tales/         ← GibberingTales — D&D 5e domain, Repo, migrations
    gibbering_tales_web/     ← GibberingTalesWeb — player/DM Phoenix app
    gibbering_tales_admin/   ← GibberingTalesAdmin — admin/support Phoenix app
```

---

## Answers

### 1. Table ownership — engine vs. Tales

**Decision: the engine is storage-agnostic forever. `gibbering_tales` owns all migrations.**

The engine has no Ecto dependency today, and this constraint is intentional and permanent. `SceneServer` holds game state in memory; the game layer is responsible for loading state from the DB and feeding it to OTP processes. The engine's relationship to storage is identical to its relationship to Phoenix: zero dependency.

This applies even to tables that are conceptually engine-level (`grid_tiles`, `maps`, `game_sessions`). Those concepts are engine-level, but the engine expresses them as in-memory structs (`Engine.State` fields). The Ecto schemas and migrations for those tables belong to `gibbering_tales`, because `gibbering_tales` is the persistence layer. The engine never imports Ecto.

An external game developer using `gibbering_engine` from Hex brings their own Repo entirely — the engine provides no schema help. `gibbering_tales` and its migrations are the reference pattern for how to persist engine state, not a shared library.

### 2. Docker and build implications

**Volume paths stay unchanged. `Dockerfile.dev` needs one addition. Tests and server work from the umbrella root.**

In a Mix umbrella, the root `mix.exs` declares `apps_path: "apps"` — it aggregates all apps and their deps. Each app also has its own `mix.exs` declaring app-specific deps, but shared deps are deduplicated at the root `deps/` directory. Named volumes (`deps_cache → /app/deps`, `build_cache → /app/_build`) need no path changes — the umbrella root is still at `/app`.

The one required change to `Dockerfile.dev`: before `mix deps.get`, each app's `mix.exs` must be copied so dep resolution includes all apps' deps. The current pattern (`COPY mix.exs mix.lock ./`) must expand to also copy `apps/*/mix.exs` in a directory-preserving way. This is the only structural change needed to the Dockerfile.

`mix test` from the umbrella root runs all apps' tests — standard umbrella behaviour. `mix phx.server` from the umbrella root starts all Application supervisors, including both Phoenix endpoints. The two web apps must listen on different ports (`gibbering_tales_web` on 4000, `gibbering_tales_admin` on 4001). `compose.yaml` exposes port 4000 today; add 4001 for admin.

**`docs/` stays at the umbrella root.** It is not split between apps — that would fragment the project's documentation for no benefit. The umbrella's purpose is compile-time code boundary enforcement, not directory organisation. All architecture docs, issue tracker, and brainstorming files remain at the top level.

### 3. Config split

**Root `config/` is shared. Each app config block is keyed by the app's new OTP atom.**

Mix umbrella `config/` at the root applies to all apps. After the OTP app renames, config blocks split as follows:

- **`config :gibbering_engine`** — EventBus adapter, MetricsStore adapter, PubSub name
- **`config :gibbering_tales`** — `ecto_repos: [GibberingTales.Repo]`, Repo credentials, Catalogue.Cache
- **`config :gibbering_tales_web`** — `GibberingTalesWeb.Endpoint` (port 4000, `secret_key_base` for dev/test), esbuild/tailwind profile `:gibbering_tales_web`, Phoenix live reload patterns
- **`config :gibbering_tales_admin`** — `GibberingTalesAdmin.Endpoint` (port 4001, **separate** `secret_key_base`), esbuild/tailwind profile `:gibbering_tales_admin`
- **Shared at root** — Logger, `config :phoenix, :json_library, Jason`, `config :phoenix_live_view` dev flags

`GibberingTalesAdmin` gets its **own `secret_key_base`** — they are different Phoenix applications with separate cookie signing needs. In prod, two env vars: `SECRET_KEY_BASE` (web) and `ADMIN_SECRET_KEY_BASE` (admin).

`runtime.exs` gains two blocks — one per web endpoint — each reading its own env var. The `GibberingTales.Repo` prod block stays under `:gibbering_tales`. The admin app reads the same `DATABASE_URL` (same DB) but through `GibberingTalesAdmin.Repo`.

### 4. Migration sequencing

**Decision: incremental, app-by-app, four implementation sub-issues (#168–#171).**

The umbrella structure requires all four apps to exist in `apps/` before the root compiles (the root `mix.exs` references them). This means the skeleton must be created first (Phase 2a), but each app can start with an empty `lib/`. Code then moves app-by-app in subsequent phases, each independently committable and test-passing.

Safe order, based on the dependency graph (`tales_web → tales → engine`, `tales_admin → tales`):

1. **Phase 2a (#168) — Umbrella scaffold:** create root `mix.exs`, four skeleton apps, update `Dockerfile.dev`, split config, update `compose.yaml`. Zero code moved. Existing tests pass from the new umbrella root.
2. **Phase 2b (#169) — Engine extraction:** move `Engine.*`, `EventBus`, `Ruleset`, `Events.*`, `Monitoring.*`, `IsoProjection` into `gibbering_engine`. Move engine tests. Verify `gibbering_engine` compiles with no Ecto/Phoenix deps.
3. **Phase 2c (#170) — Tales domain extraction:** move `Rulesets.DnD5e`, `Catalogue.*`, `Data.*`, `Accounts`, `Campaigns`, `Characters`, `Pipeline.LegalGuard`, `Repo`, and all non-admin migrations into `gibbering_tales`. Move domain + integration tests.
4. **Phase 2d (#171) — Web + Admin extraction:** move all LiveViews/controllers/components into `gibbering_tales_web`; move `Gibbering.Admin.*`, `admin_*` controllers, `RequireSupportUser` plug, and admin migrations into `gibbering_tales_admin` with its own Repo.

Tests move with their home app at each phase. No test-suite big-bang at the end.

### 5. Admin-only schema placement

**Decision: `SupportUser` and `AuditLog` live in `gibbering_tales_admin`, which gets its own Repo.**

`gibbering_tales_admin` defines `GibberingTalesAdmin.Repo` — a second Repo pointing at the same PostgreSQL DB. Admin migrations (`create_support_users`, `create_support_audit_logs`) move to `apps/gibbering_tales_admin/priv/repo/migrations/`. Config lists both repos under their respective OTP apps (`ecto_repos` per app). `mix ecto.migrate` from the umbrella root runs all configured repos' migrations.

This gives compile-time enforcement: `gibbering_tales_web` cannot reference `GibberingTalesAdmin.SupportUser` because it does not depend on `gibbering_tales_admin`. That boundary is structurally impossible, not convention-based.

The current `Gibbering.Admin` context module touches both admin schemas (`SupportUser`, `AuditLog`) and tales schemas (`User`, `Campaign`, `Character`). After extraction, the admin context module lives in `gibbering_tales_admin` and uses **both Repos**: `GibberingTalesAdmin.Repo` for admin-only tables, `GibberingTales.Repo` for read queries against tales tables. This is correct because `gibbering_tales_admin → gibbering_tales` in the dependency graph.

---

## Implementation sub-issues

| # | Phase | Scope |
|---|---|---|
| [#168](168-phase2a-umbrella-scaffold.md) | 2a | Umbrella scaffold — root mix.exs, skeleton apps, Dockerfile, config, compose |
| [#169](169-phase2b-engine-extraction.md) | 2b | Engine extraction — move engine modules and tests into `gibbering_engine` |
| [#170](170-phase2c-tales-domain-extraction.md) | 2c | Tales domain extraction — move D&D domain, Repo, migrations into `gibbering_tales` |
| [#171](171-phase2d-web-admin-extraction.md) | 2d | Web + Admin extraction — move LiveViews into `gibbering_tales_web`; Admin context + Repo into `gibbering_tales_admin` |

---

## Acceptance criteria

- [x] All five question groups above have a written answer in this issue or a linked ADR
- [x] Table ownership decision is documented — which tables (if any) are conceptually engine-level and how that affects the Repo split
- [x] Docker approach is validated (spike or written analysis) — umbrella builds work in the container
- [x] Migration order is sequenced into 3–4 implementation sub-issues (Phase 2a, 2b, 2c…)
- [x] Each sub-issue has scope narrow enough to be completed and passing tests on its own branch
