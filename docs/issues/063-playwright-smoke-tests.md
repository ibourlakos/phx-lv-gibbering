# #63 · Playwright smoke test suite + smoke Docker environment

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** ops, architecture

End-to-end smoke tests driven by a real browser (Playwright/Chromium) running inside Docker, exercising the full HTTP + LiveView + WebSocket stack. Sits above the existing three test layers as an optional fourth layer — not run in every CI commit but triggered pre-merge or on a release candidate.

A separate **smoke environment** isolates this from the dev DB: dedicated Postgres database (`gibbering_smoke`), seeded with known fixture users and one seed campaign, reset between runs.

## Design notes

**Smoke environment options (decide during implementation):**

- Option A — `MIX_ENV=smoke`: new Mix environment with its own `config/smoke.exs`, own DB config, and a `mix smoke` alias that starts the app + runs Playwright. Cleanest separation; requires a third compiled variant.
- Option B — `MIX_ENV=dev` with a `smoke` Compose profile: app runs in dev mode against a `gibbering_smoke` DB; a separate `playwright` service in `compose.yaml` under the `smoke` profile runs the suite. No new Mix env needed.

Option B is likely simpler and avoids tripling the Dockerfile build stages.

**Playwright service:** Use `mcr.microsoft.com/playwright:v1.x-jammy` (all deps baked in). Mount the `test/smoke/` directory. The service targets `http://app:4000` and runs `npx playwright test`.

**Invocation:**
```bash
docker compose --profile smoke up --abort-on-container-exit playwright
```

## Acceptance criteria

- [ ] `test/smoke/` directory exists with a `playwright.config.ts` pointing at `http://app:4000`
- [ ] `compose.yaml` has a `playwright` service under the `smoke` profile, using the official Playwright image
- [ ] Smoke database (`gibbering_smoke`) is seeded with a known player account and one campaign before each run
- [ ] Smoke suite covers the core happy paths:
  - [ ] Register a new account and log in
  - [ ] Create a character via the 6-step modal; character appears in roster
  - [ ] Join a campaign from the home page
  - [ ] Open the lobby and navigate to the game
  - [ ] Select a hero and move it one tile
- [ ] Screenshots are captured on failure and written to `test/smoke/screenshots/`
- [ ] `docs/dev-setup.md` documents the `docker compose --profile smoke` invocation
- [ ] Smoke suite passes end-to-end in CI (separate job, allowed to fail on feature branches, required on `main`)
