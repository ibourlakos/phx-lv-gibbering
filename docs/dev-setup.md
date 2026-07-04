# Dev Setup — Quick Reference

> Keep this file current. Update it whenever a tool, version, or workflow step changes.

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Docker | 29+ | [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine |
| Docker Compose | V2 plugin | Bundled with Docker 29+. Use `docker compose`, not `docker-compose` |
| Git LFS | 3.0+ | `sudo apt install git-lfs` (Debian/Ubuntu) · `brew install git-lfs` (macOS) |

That's it. Elixir, Erlang, and Node run inside containers.

> **Git LFS is required.** Binary assets (sprites, fonts, audio) are tracked via LFS. Cloning without it will give you pointer files instead of actual assets.

---

## First-Time Setup

```bash
# 1. Clone and enter the repo
git clone git@github.com:ibourlakos/phx-lv-gibbering.git
cd phx-lv-gibbering

# 2. Activate Git LFS (once per machine)
git lfs install

# 3. Build the app image and start all services
#    (dev env vars are hardcoded in compose.yaml — no .env file needed)
docker compose up --build

# 4. In a second terminal — create and migrate the database
docker compose exec app mix ecto.setup

# App is now at http://localhost:4000
```

---

## Daily Workflow

```bash
# Start all services (detached)
docker compose up -d

# Follow logs
docker compose logs -f app

# Open an interactive Elixir shell inside the running container
docker compose exec app iex -S mix

# Run any mix command inside the container
docker compose exec app mix <command>

# Run tests
# Note: the test DB requires catalogue data for Cache tests. Seed it once after
# first creating the test DB (or after mix ecto.reset with MIX_ENV=test):
#   docker compose exec -e MIX_ENV=test app mix run priv/repo/seeds.exs
docker compose exec app mix test

# Format code
docker compose exec app mix format

# Stop all services
docker compose down
```

---

## Database

```bash
# Run migrations
docker compose exec app mix ecto.migrate

# Roll back one migration
docker compose exec app mix ecto.rollback

# Generate a new migration
docker compose exec app mix ecto.gen.migration <name>

# Reset (drop + recreate + migrate + seed)
docker compose exec app mix ecto.reset

# Connect directly to Postgres
docker compose exec db psql -U gibbering -d gibbering_dev

# Wipe the database volume (nuke all data)
docker compose down -v
docker compose up -d
docker compose exec app mix ecto.setup
```

Databases:
- Dev: `gibbering_dev`
- Test: `gibbering_test` (created automatically during `mix test`)

---

## Playwright Smoke Tests

Playwright runs as a separate Docker service under the `smoke` profile, targeting the running dev app. No extra Mix environment or database needed — the dev DB and dev app are used.

**Prerequisite:** the dev app must be running and seeded (`mix ecto.setup`).

```bash
# Run the full smoke suite (headless Chromium, inside Docker)
docker compose --profile smoke run --rm playwright

# Re-run without re-fetching npm deps (faster if node_modules is cached)
docker compose --profile smoke run --rm playwright npx playwright test

# Screenshots on failure land in test/smoke/screenshots/
```

Tests live in `test/smoke/tests/`. They cover auth flows, the characters roster, character creation modal, lobby navigation, and the game SVG board.

---

## SRD Data Pipeline

```bash
docker compose exec app mix gibbering.ingest
```

Fetches D&D 5e SRD monsters from the Open5e API (CC-BY-4.0), filters WotC Product Identity via `LegalGuard`, and upserts into the `monsters` table. The task is idempotent — re-running skips already-present entries.

```bash
# Dry run — fetch and parse without writing to DB
docker compose exec app mix gibbering.ingest --dry-run
```

---

## Docker Housekeeping

Run these periodically to keep the local Docker environment clean.

```bash
# Remove stopped containers
docker compose rm -f

# Remove dangling images (untagged build leftovers)
docker image prune -f

# Remove unused build cache
docker builder prune -f

# Full clean — removes ALL unused images, networks, and build cache
# (does NOT remove named volumes by default — your data is safe)
docker system prune -f

# Nuclear option — also removes unused volumes (destroys db_data)
docker system prune -f --volumes
```

When rebuilding after dependency changes (`mix.lock` updated):

```bash
# Rebuild the app image (recompiles deps for dev + test inside the image layer)
docker compose build app
docker compose up -d

# If you get permission errors from stale volumes after a UID-changing rebuild:
docker compose down
docker volume rm phx-lv-gibbering_deps_cache phx-lv-gibbering_build_cache
docker compose up -d
```

**After refactors that delete Elixir source modules** (e.g. app extractions, renames), restart the dev server. Phoenix's code reloader cannot hot-reload a deleted module — it purges it from memory mid-request, causing `UndefinedFunctionError`. A restart loads the clean build from scratch.

```bash
docker compose restart app
# or for a full stop/start:
docker compose down && docker compose up -d
```

`mix clean` does not remove beams for deleted sources (Mix only tracks currently-compiled files). If stale beams persist after a restart, wipe the build cache volume:

```bash
docker compose down
docker volume rm phx-lv-gibbering_build_cache
docker compose up -d
```

> **Why deps are compiled into the image**: `Dockerfile.dev` runs `MIX_ENV=dev mix deps.compile` and `MIX_ENV=test mix deps.compile` so that named volumes (`build_cache`) are seeded with pre-compiled deps on first creation. This avoids a long recompilation step inside the container. The tradeoff is a slower `docker compose build` after `mix.lock` changes.

---

## Other Environments

- [docs/qa-setup.md](qa-setup.md) — QA environment (placeholder; see issue [#62](issues/062-multi-environment-infra.md))
- [docs/prod-setup.md](prod-setup.md) — Production environment (placeholder; see issue [#62](issues/062-multi-environment-infra.md))

> **Security note for non-dev environments:** the `/admin` route scope must be restricted to an internal network or VPN at the reverse proxy level. See the Security section in each environment doc.

---

## Environment Variables

| Variable | Default (dev) | Notes |
|---|---|---|
| `DATABASE_URL` | `ecto://gibbering:gibbering@db/gibbering_dev` | `db` = Docker service name |
| `SECRET_KEY_BASE` | see `compose.yaml` | Generate a real one with `mix phx.gen.secret` |
| `PHX_HOST` | `localhost` | Change for production |
| `MIX_ENV` | (not set — Mix defaults to `dev` for server, `test` for `mix test`) | Do not set this globally; let Mix choose per task |