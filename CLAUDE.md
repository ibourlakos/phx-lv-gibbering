# The Gibbering Engine

A turn-based D&D 5e tactical grid game — Elixir + Phoenix LiveView, pure SVG rendering, no client-side game framework.

Named after the Gibbering Mouther (SRD-legal aberration). The architecture is the aberration.

---

## Docs

- [Architecture](docs/architecture.md) — module map, ruleset behaviour, SVG pipeline, data pipeline
- [Data Model](docs/data-model.md) — DB schema, runtime State struct, static reference data
- [Dev Setup](docs/dev-setup.md) — prerequisites, workflow, DB ops, Docker housekeeping
- [Testing](docs/testing.md) — three-layer strategy, fixtures, TDD workflow, running tests
- [Workflow](docs/workflow.md) — the full dev sequence: Brainstorm → Explore → Issue → Branch → Red → Green → Refactor → Verify → Commit
- [Legal](docs/legal.md) — content licenses, assets, data sources, privacy, LegalGuard scope
- [Git Policy](docs/git-policy.md) — conventional commits, branch naming, LFS for binary assets

## Stack

- Elixir 1.18 / OTP 27 (runs in Docker — no local install needed)
- Phoenix LiveView + PubSub
- PostgreSQL 17 (Docker)

## Legal

Any unresolved legal issue is a blocker. See [docs/legal.md](docs/legal.md) for the full reference covering content licenses, art assets, data sources, dependencies, and privacy.

## Brainstorming Log

Brainstorming files live in [`docs/brainstorming/`](docs/brainstorming/). See the [README](docs/brainstorming/README.md) for counter rules and workflow.

| File | Topic | Status |
|---|---|---|
| [`docs/brainstorming/06-investigate-initial-high-level-dnd-semantics.md`](docs/brainstorming/06-investigate-initial-high-level-dnd-semantics.md) | D&D 5e semantic graph: actors, spells, items, conditions, action resolution | exploration |

## Dev Setup (short form)

```bash
cp .env.example .env
docker compose up --build
docker compose exec app mix ecto.setup
# http://localhost:4000
```

See [docs/dev-setup.md](docs/dev-setup.md) for the full reference.

## Issue Tracker

Issues live in `.issues/`. Start at [`.issues/README.md`](.issues/README.md) for the full index and open issue list.

- **Counter:** `.issues/counter` (plain integer — next number to use)
- **One file per issue:** `.issues/<N>-<slug>.md` (open and closed issues both kept)
- **Tags:** `bug`, `rules`, `architecture`, `legal`, `ops`, `discovery`, `rendering`, `gameplay`
- **Statuses:** `open` (backlog) → `wip` (active branch or session) → `closed`; `deferred` (explicitly parked — requires a reason) can transition back to `open` when unblocked

**To add an issue:** read `counter`, use that number, create `.issues/<N>-<slug>.md`, increment `counter`, add a row to the open issues table in `.issues/README.md`, commit as `chore: add issue #N`.  
**To close an issue:** in the issue file change `**Status:** open` → `**Status:** closed` and add `**Closed:** YYYY-MM-DD`, move its row from Open to Closed in `.issues/README.md`, commit as `chore: close issue #N`.  
**To defer an issue:** change `**Status:** open` → `**Status:** deferred`, add `**Deferred because:** <reason>`, move its row from Open to Deferred in `.issues/README.md`, commit as `chore: defer issue #N`.

Issue file format (`.issues/<N>-<slug>.md`):
```
# #N · Title
**Status:** open | wip | deferred | closed
**Opened:** YYYY-MM-DD
**Closed:** YYYY-MM-DD        ← only when closed
**Deferred because:** <reason> ← only when deferred
**Priority:** high | medium | low
**Tags:** tag1, tag2

Description.

**Acceptance criteria**
- [ ] ...
```

## Claude Instructions

- Be concise in responses.
- If you feel that my feedback, ideas, or suggestions are getting out hand, keep me checked.
- **Follow [docs/workflow.md](docs/workflow.md) for every non-trivial change.** The sequence is: Brainstorm → Explore → Issue → Branch → Red → Green → Refactor → Verify → Commit. Never skip the Legal gate or the Verify phase.
- Dev environment is fully Docker-based. Never assume local Elixir/Node installs. All `mix` commands go through `docker compose exec app mix`.
- Keep [docs/dev-setup.md](docs/dev-setup.md) up-to-date when tools, versions, or workflows change.
- Maintain Docker hygiene: avoid leaving dangling images or stopped containers. Prefer `docker compose down` over `docker stop`, use named volumes, and document prune commands when adding new services.
- Legal is a hard blocker. Before committing any asset (image, font, data file) or adding a data source/dependency, verify its license against [docs/legal.md](docs/legal.md). When in doubt, flag it rather than proceed.
- Follow [docs/git-policy.md](docs/git-policy.md) for all commits: conventional commits format (`type(scope): subject`), one logical change per commit, never commit directly to `main`. Binary assets require Git LFS — do not commit them until LFS is configured.
- Tests live in three layers — see [docs/testing.md](docs/testing.md). Always start at the lowest applicable layer (pure functions first). Run `mix precommit` before every commit.