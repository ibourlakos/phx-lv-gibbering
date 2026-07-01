# #168 · Engine decomposition Phase 2a — Umbrella scaffold

**Status:** open
**Opened:** 2026-07-01
**Priority:** high
**Tags:** architecture, ops

Create the umbrella project structure, update Docker and config, and verify the existing test suite passes from the new umbrella root — without moving any code.

Derived from discovery issue #167. Prerequisite for #169, #170, #171.

---

## Scope

- Rename or restructure the project root to `gibbering_umbrella/`
- Write the umbrella root `mix.exs` (`apps_path: "apps"`, `deps:` shared deps only)
- Create four skeleton apps with `mix.exs` and empty `lib/` dirs:
  - `apps/gibbering_engine/`
  - `apps/gibbering_tales/`
  - `apps/gibbering_tales_web/`
  - `apps/gibbering_tales_admin/`
- Update `Dockerfile.dev` to COPY each app's `mix.exs` before `mix deps.get` (required so dep resolution sees all apps' deps)
- Split `config/config.exs` into umbrella-root shared blocks + per-app OTP atom keys:
  - `:gibbering_engine` — EventBus adapter, MetricsStore adapter
  - `:gibbering_tales` — ecto_repos, Repo credentials
  - `:gibbering_tales_web` — Endpoint (port 4000), esbuild/tailwind profile
  - `:gibbering_tales_admin` — Endpoint (port 4001), separate secret_key_base, esbuild/tailwind profile
- Update `runtime.exs` — two prod blocks, one per Phoenix endpoint, each reading its own env var
- Update `compose.yaml` — expose port 4001 for the admin endpoint
- `docs/` stays at umbrella root, no changes needed

## Out of scope

No application code moves in this phase. `lib/` stays in place (the existing monolith still lives at the project root or in the first app depending on migration strategy). The goal is a compilable skeleton that produces green tests.

## Acceptance criteria

- [ ] `docker compose exec app mix compile --warnings-as-errors` passes from umbrella root
- [ ] `docker compose exec app mix test` passes from umbrella root
- [ ] `docker compose exec app mix precommit` passes
- [ ] `Dockerfile.dev` correctly copies per-app `mix.exs` files before `mix deps.get`
- [ ] Both Phoenix endpoints are configured on distinct ports in dev config
- [ ] No application code has moved — diff is purely structural/config
