# The Gibbering Engine

A turn-based D&D 5e tactical grid game — Elixir + Phoenix LiveView, pure SVG rendering, no client-side game framework.

Named after the Gibbering Mouther (SRD-legal aberration). The architecture is the aberration.

---

## Docs

- [Architecture](docs/architecture.md) — TOC; sub-docs in `docs/architecture/` (data model, context map, bounded contexts, event system, CQRS, predicate vocabulary) and `docs/architecture/features/` (rendering, fog of war, DM overrides, etc.)
- [Dev Setup](docs/dev-setup.md) — prerequisites, workflow, DB ops, Docker housekeeping
- [Testing](docs/testing.md) — three-layer strategy, fixtures, TDD workflow, running tests
- [Workflow](docs/workflow.md) — seven paths for discovery, feature, bugfix, hotfix, work packages, escalation, and docs-only changes
- [Legal](docs/legal.md) — content licenses, assets, data sources, privacy, LegalGuard scope
- [Git Policy](docs/git-policy.md) — conventional commits, branch naming, LFS for binary assets
- [AI Memory](docs/ai-memory.md) — context-budget tiers (push-full/push-head/pull), CLAUDE.md size cap and escalation order

## Stack

- Elixir 1.18 / OTP 27 (runs in Docker — no local install needed)
- Phoenix LiveView + PubSub
- PostgreSQL 17 (Docker)

## Legal

Any unresolved legal issue is a blocker. See [docs/legal.md](docs/legal.md) for the full reference covering content licenses, art assets, data sources, dependencies, and privacy.

## Brainstorming Log

Brainstorming files live in [`docs/brainstorming/`](docs/brainstorming/). See the [README](docs/brainstorming/README.md) for the active log, counter rules, and workflow.

## Dev Setup (short form)

```bash
docker compose up --build
docker compose exec app mix ecto.setup
# http://localhost:4000
```

Dev env vars are hardcoded in `compose.yaml` — no `.env` file needed.

See [docs/dev-setup.md](docs/dev-setup.md) for the full reference.

## Issue Tracker

Issues live in `docs/issues/`. Start at [`docs/issues/README.md`](docs/issues/README.md) for the full index, tags, and lifecycle commands (add/close/defer/block/cancel).

## Claude Instructions

- Be concise in responses.
- If you feel that my feedback, ideas, or suggestions are getting out hand, keep me checked.
- **Follow [docs/workflow.md](docs/workflow.md) for every non-trivial change.** Pick the correct path (A–G) for the type of work. Never skip the Legal gate or the Verify phase.
- Dev environment is fully Docker-based. Never assume local Elixir/Node installs. All `mix` commands go through `docker compose exec app mix`.
- Keep [docs/dev-setup.md](docs/dev-setup.md) up-to-date when tools, versions, or workflows change.
- Maintain Docker hygiene: avoid leaving dangling images or stopped containers. Prefer `docker compose down` over `docker stop`, use named volumes, and document prune commands when adding new services.
- Legal is a hard blocker. Before committing any asset (image, font, data file) or adding a data source/dependency, verify its license against [docs/legal.md](docs/legal.md). When in doubt, flag it rather than proceed.
- Follow [docs/git-policy.md](docs/git-policy.md) for all commits: conventional commits format (`type(scope): subject`), one logical change per commit, never commit directly to `main`. Binary assets require Git LFS — do not commit them until LFS is configured.
- Never use `git add -A` or `git add .`. Stage only the specific files relevant to the current change, to avoid sweeping in unrelated untracked files.
- Tests live in three layers — see [docs/testing.md](docs/testing.md). Always start at the lowest applicable layer (pure functions first). Run `mix precommit` before every code commit (not required for docs-only changes).
- When starting OTP processes (e.g. `SceneServer` `start_link`/`init`), check the result and handle stale IDs gracefully rather than raising on bad input.
