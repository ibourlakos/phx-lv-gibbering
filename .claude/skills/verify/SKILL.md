---
name: verify
description: Drive the running Gibbering app to observe a change, rather than just running tests.
---

# Verifying a change in this repo

No headless browser tooling is installed (no Playwright/Wallaby) — verify LiveView
changes via curl against the dev server's dead-render HTML. This proves the template
compiles and executes end-to-end with real seeded data, though it won't catch
client-side JS/hook behavior or interactive (connected) LiveView updates.

## Setup

```bash
docker compose up -d          # app on :4000, db on :5432
docker compose exec app mix ecto.migrate
docker compose exec app mix run apps/gibbering/priv/repo/seeds.exs   # idempotent-ish; ok to rerun
```

Seeded users (password `gibbering` for all): `dungeon_master`, `alice`, `bob`, `charlie`.
Seeded campaigns: `/game/3` (Duskwood Crossing, outdoor forest map), `/game/4` (The Sunken
Crypt, DM-solo, indoor two-chamber map — has the `edges` door in `maps.edges`).

## Log in and hit a LiveView route

```bash
cd <scratchpad>
curl -s -c cookies.txt http://localhost:4000/login -o login.html
csrf=$(grep -o 'name="_csrf_token" value="[^"]*"' login.html | head -1 | sed 's/.*value="//;s/"//')

curl -s -b cookies.txt -c cookies.txt -o login_result.html -w "%{http_code}\n" \
  --data-urlencode "_csrf_token=$csrf" \
  --data-urlencode "session[username]=dungeon_master" \
  --data-urlencode "session[password]=gibbering" \
  -X POST http://localhost:4000/login
# 302 = success

curl -s -b cookies.txt -o game.html -w "%{http_code}\n" http://localhost:4000/game/4
```

Note the login form fields are `session[username]` / `session[password]`, not
`user[...]` — easy to get wrong on a cold guess.

## What to check in the HTML

- `grep -c "<polygon" game.html` — one diamond per rendered tile/entity/overlay;
  a drop to 0 usually means the LiveView crashed and Phoenix served an error page instead.
- `grep -Eio "exception|stacktrace" game.html` — should be empty.
- `docker compose logs app --tail 60 | grep -iE "error|exception"` — check the
  server didn't log a crash while rendering.
- `grep -o 'points="[^"]*"' game.html | head` — sanity-check the isometric
  coordinates are integers in a plausible pixel range for the map's `tile_size`.

## Gotchas

- `mix ecto.reset` will fail with `object_in_use` if the running `app` container
  already holds connections — just re-run `mix ecto.migrate` + the seeds script
  directly instead of dropping the DB.
- Rendering logic (isometric projection, coordinate helpers) lives in
  `GibberingEngine.Projection.Isometric` / `GibberingEngine.Coords`, wired into
  `apps/gibbering_tales_web/lib/gibbering_tales_web/live/game_live.html.heex`.
