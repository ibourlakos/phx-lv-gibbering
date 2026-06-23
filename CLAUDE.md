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

## Stack

- Elixir 1.18 / OTP 27 (runs in Docker — no local install needed)
- Phoenix LiveView + PubSub
- PostgreSQL 17 (Docker)

## Legal

Any unresolved legal issue is a blocker. See [docs/legal.md](docs/legal.md) for the full reference covering content licenses, art assets, data sources, dependencies, and privacy.

## Brainstorming Log

Brainstorming files live in [`docs/brainstorming/`](docs/brainstorming/). See the [README](docs/brainstorming/README.md) for counter rules and workflow.

| # | File | Topic | Status |
|---|---|---|---|
| 18 | [18-inspection-panel.md](docs/brainstorming/18-inspection-panel.md) | Inspection / Detail Panel — click-to-inspect map elements, selection model, role gating | open |
| 19 | [19-unified-action-model.md](docs/brainstorming/19-unified-action-model.md) | Unified Action Model — general Action struct covering spells, attacks, improvised, social | open |
| 20 | [20-display-testing.md](docs/brainstorming/20-display-testing.md) | Display Testing — verifying role-gated and state-dependent SVG output | open |
| 21 | [21-movement-action-gate-and-cost-overlay.md](docs/brainstorming/21-movement-action-gate-and-cost-overlay.md) | Movement action gate + cost-coloured overlay — on-demand overlay, terrain cost feedback | open |
| 22 | [22-dm-entity-panel-redesign.md](docs/brainstorming/22-dm-entity-panel-redesign.md) | DM entity panel redesign — right panel as catalog, adjustments in left panel DM tab | open |
| 23 | [23-composable-entity-appearances.md](docs/brainstorming/23-composable-entity-appearances.md) | Composable entity appearances — skeleton archetypes, socket model, 4-way facing, proportions | open |
| 25 | [25-elevation.md](docs/brainstorming/25-elevation.md) | Elevation — logical Z, SVG render sort, structure interiors, line of sight | open |
| 26 | [26-tile-occupancy-and-traversability.md](docs/brainstorming/26-tile-occupancy-and-traversability.md) | Tile occupancy and traversability — 5-category taxonomy, effects layer, computed traversability, ice slip test case | open |
| 27 | [27-coordinate-model-and-spatial-addressing.md](docs/brainstorming/27-coordinate-model-and-spatial-addressing.md) | Coordinate model and spatial addressing — tile grain, elevated surfaces, interior spaces, teleportation destinations | open |
| 28 | [28-player-dice-roll-prompt-and-auto-roll.md](docs/brainstorming/28-player-dice-roll-prompt-and-auto-roll.md) | Player dice roll prompt + auto-roll preference — pending-roll state, prompt UI, per-player toggle | open |
| 29 | [29-spinoff-plans-1-6.md](docs/brainstorming/29-spinoff-plans-1-6.md) | Spinoff game mode concepts — Plans 1–6 (Autobattler, Darkest Dungeon, Deckbuilder, Terrain Wrangling, Co-op Raid, Roguelike Tower) | open |
| 30 | [30-spinoff-plan-7-expedition-chronicle.md](docs/brainstorming/30-spinoff-plan-7-expedition-chronicle.md) | Spinoff Plan 7 — The Expedition Chronicle: structured objective-based adventure mode with Rift Stability, Leader role, Paragon Ranks, Chronicle narration | open |
| 31 | [31-freeform-dice-tray.md](docs/brainstorming/31-freeform-dice-tray.md) | Freeform dice tray — player-initiated multi-die roll, die picker UI, sequential stagger animation, always-public event feed | open |

Next brainstorm number: 32 (see `docs/brainstorming/counter`).

## Dev Setup (short form)

```bash
cp .env.example .env
docker compose up --build
docker compose exec app mix ecto.setup
# http://localhost:4000
```

See [docs/dev-setup.md](docs/dev-setup.md) for the full reference.

## Issue Tracker

Issues live in `docs/issues/`. Start at [`docs/issues/README.md`](docs/issues/README.md) for the full index and open issue list.

- **Counter:** `docs/issues/counter` (plain integer — next number to use)
- **One file per issue:** `docs/issues/<N>-<slug>.md` (all issues kept regardless of status)
- **Tags:** `bug`, `rules`, `architecture`, `legal`, `ops`, `discovery`, `rendering`, `gameplay`, `ui`, `security`, `admin`
- **Statuses:** `open` (backlog) → `in-progress` (active branch) → `closed`; `deferred` (intentionally parked), `blocked` (external dependency), `cancelled` (won't do) are side-tracks that can return to `open` when resolved

**To add an issue:** read `counter`, use that number, create `docs/issues/<N>-<slug>.md`, increment `counter`, add a row to the open issues table in `docs/issues/README.md`, commit as `chore: add issue #N`.  
**To close an issue:** change `**Status:** open` → `**Status:** closed`, add `**Closed:** YYYY-MM-DD`, move its row from Open to Closed in `docs/issues/README.md`, commit as `chore: close issue #N`.  
**To defer an issue:** change status → `deferred`, add `**Deferred because:** <reason>`, move its row to Deferred, commit as `chore: defer issue #N`.  
**To block an issue:** change status → `blocked`, add `**Blocked by:** <issue # or description>`, move its row to Blocked, commit as `chore: block issue #N`.  
**To cancel an issue:** change status → `cancelled`, add `**Cancelled:** YYYY-MM-DD` and `**Cancelled because:** <reason>`, move its row to Cancelled, commit as `chore: cancel issue #N`.

Issue file format (`docs/issues/<N>-<slug>.md`):
```
# #N · Title
**Status:** open | in-progress | deferred | blocked | cancelled | closed
**Opened:** YYYY-MM-DD
**Closed:** YYYY-MM-DD              ← only when closed
**Deferred because:** <reason>      ← only when deferred
**Blocked by:** <issue # or desc>   ← only when blocked
**Cancelled:** YYYY-MM-DD           ← only when cancelled
**Cancelled because:** <reason>     ← only when cancelled
**Priority:** high | medium | low
**Tags:** tag1, tag2

Description.

**Acceptance criteria**
- [ ] ...
```

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
- When starting OTP processes (e.g. `GameServer.init`, `start_link`), check the result and handle stale IDs gracefully rather than raising on bad input.
