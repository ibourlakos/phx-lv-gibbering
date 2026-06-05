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
git clone <repo-url>
cd phx-lv-gibbering

# 2. Activate Git LFS (once per machine)
git lfs install

# 3. Copy env file (defaults work out of the box)
cp .env.example .env

# 4. Build the app image and start all services
docker compose up --build

# 5. In a second terminal — create and migrate the database
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

## SRD Data Pipeline

```bash
docker compose exec app mix gibbering.seed_srd
```

Fetches D&D 5e SRD data, filters WotC Product Identity, and inserts into `monsters` + `spells`.

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

> **Why deps are compiled into the image**: `Dockerfile.dev` runs `MIX_ENV=dev mix deps.compile` and `MIX_ENV=test mix deps.compile` so that named volumes (`build_cache`) are seeded with pre-compiled deps on first creation. This avoids a long recompilation step inside the container. The tradeoff is a slower `docker compose build` after `mix.lock` changes.

---

## Other Environments

- [docs/qa-setup.md](qa-setup.md) — QA environment (placeholder; see issue [#62](../.issues/062-multi-environment-infra.md))
- [docs/prod-setup.md](prod-setup.md) — Production environment (placeholder; see issue [#62](../.issues/062-multi-environment-infra.md))

> **Security note for non-dev environments:** the `/admin` route scope must be restricted to an internal network or VPN at the reverse proxy level. See the Security section in each environment doc.

---

## Environment Variables

| Variable | Default (dev) | Notes |
|---|---|---|
| `DATABASE_URL` | `ecto://gibbering:gibbering@db/gibbering_dev` | `db` = Docker service name |
| `SECRET_KEY_BASE` | see `.env.example` | Generate a real one with `mix phx.gen.secret` |
| `PHX_HOST` | `localhost` | Change for production |
| `MIX_ENV` | (not set — Mix defaults to `dev` for server, `test` for `mix test`) | Do not set this globally; let Mix choose per task |