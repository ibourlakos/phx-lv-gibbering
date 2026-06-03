# The Gibbering Engine

A turn-based D&D 5e tactical grid game — Elixir + Phoenix LiveView, pure SVG rendering, no client-side game framework.

Named after the Gibbering Mouther (SRD-legal aberration). The architecture is the aberration.

---

## Docs

- [Architecture](docs/architecture.md) — module map, ruleset behaviour, SVG pipeline, data pipeline
- [Dev Setup](docs/dev-setup.md) — prerequisites, workflow, DB ops, Docker housekeeping
- [Testing](docs/testing.md) — three-layer strategy, fixtures, TDD workflow, running tests
- [Legal](docs/legal.md) — content licenses, assets, data sources, privacy, LegalGuard scope
- [Git Policy](docs/git-policy.md) — conventional commits, branch naming, LFS for binary assets

## Stack

- Elixir 1.18 / OTP 27 (runs in Docker — no local install needed)
- Phoenix LiveView + PubSub
- PostgreSQL 17 (Docker)

## Legal

Any unresolved legal issue is a blocker. See [docs/legal.md](docs/legal.md) for the full reference covering content licenses, art assets, data sources, dependencies, and privacy.

## Brainstorming Log

| File | Topic |
|---|---|
| `.claude/brainstorming/initial-gemini.md` | Stack selection, engine naming, SVG approach, SRD pipeline |
| `.claude/brainstorming/splitting-the-grimoire.md` | Engine vs. ruleset separation; Ruleset behaviour pattern |

## Dev Setup (short form)

```bash
cp .env.example .env
docker compose up --build
docker compose exec app mix ecto.setup
# http://localhost:4000
```

See [docs/dev-setup.md](docs/dev-setup.md) for the full reference.

## Issue Tracker

Issues live in `.issues/`, one file per aspect. Current aspects: `ops.md`.  
The next issue number is in `.issues/counter` (plain integer, one per line).

**To add an issue:** read `counter`, use that number, append the entry to the right aspect file, increment `counter`, commit as `chore: add issue #N`.  
**To close an issue:** change `**Status:** open` → `**Status:** closed`, add `**Closed:** YYYY-MM-DD`, commit as `chore: close issue #N`.

Issue format:
```
## #N · Title
**Status:** open
**Opened:** YYYY-MM-DD
**Priority:** high | medium | low

Description.

**Acceptance criteria**
- [ ] ...
```

## Claude Instructions

- Be concise in responses.
- Dev environment is fully Docker-based. Never assume local Elixir/Node installs. All `mix` commands go through `docker compose exec app mix`.
- Keep [docs/dev-setup.md](docs/dev-setup.md) up-to-date when tools, versions, or workflows change.
- Maintain Docker hygiene: avoid leaving dangling images or stopped containers. Prefer `docker compose down` over `docker stop`, use named volumes, and document prune commands when adding new services.
- Legal is a hard blocker. Before committing any asset (image, font, data file) or adding a data source/dependency, verify its license against [docs/legal.md](docs/legal.md). When in doubt, flag it rather than proceed.
- Follow [docs/git-policy.md](docs/git-policy.md) for all commits: conventional commits format (`type(scope): subject`), one logical change per commit, never commit directly to `main`. Binary assets require Git LFS — do not commit them until LFS is configured.