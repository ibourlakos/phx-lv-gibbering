# #174 · Retire the legacy `apps/gibbering` shell app
**Status:** open
**Opened:** 2026-07-03
**Priority:** medium
**Tags:** ops, architecture

Phase 2 (WP-S) converted the project to what its docs call a four-app umbrella, but a
fifth app remains: `apps/gibbering`, a shell with an empty supervisor and 28 tracked
files. It still owns live infrastructure and stale duplicates:

- **Live:** `priv/repo/seeds.exs` — the root `ecto.setup` alias points at
  `apps/gibbering/priv/repo/seeds.exs` (see root `mix.exs`)
- **Live:** `test/smoke/` — `compose.yaml` mounts `./apps/gibbering/test/smoke` for the
  Playwright smoke profile
- **Duplicate:** `assets/` — byte-identical copy of `apps/gibbering_tales_web/assets/js/app.js`
  plus vendor JS and css; divergence risk
- **Stale:** `priv/static/` (favicon, robots.txt, images, art-reference), `priv/gettext/`,
  `priv/repo/migrations/` (empty — real migrations live in `apps/gibbering_tales/priv/repo`)

**Acceptance criteria**
- [ ] `seeds.exs` moved to `apps/gibbering_tales/priv/repo/seeds.exs`; root `ecto.setup` alias updated (coordinate with #141 seeds decomposition — do not duplicate effort)
- [ ] Smoke tests moved (e.g. to `apps/gibbering_tales_web/test/smoke/` or a top-level `test/smoke/`); `compose.yaml` playwright mount updated; `.gitignore` smoke patterns updated to match
- [ ] Duplicate `assets/`, stale `priv/static/`, `priv/gettext/`, empty migrations dir deleted after verifying the web app copies are the live ones
- [ ] `apps/gibbering` removed from the umbrella; `mix precommit` and smoke profile pass
- [ ] Docs updated where they say "four-app umbrella" or reference `apps/gibbering` paths
