# #193 · Doc rot: stale file references across workflow/testing docs

**Status:** open
**Opened:** 2026-09-20
**Priority:** low
**Tags:** ops

A batch of stale references accumulated across the AI-governance docs,
found during an external review pass. Individually small; jointly they
train an agent (or a human) to skim the docs skeptically, which defeats
the purpose of a guidelines corpus. Path [G] docs-only batch.

1. `docs/workflow.md:79` points to `test/engine/game_server_test.exs` —
   `GameServer` was renamed `SceneServer`; the real Layer-2 test file is
   `apps/gibbering_tales_web/test/engine/scene_server_test.exs`.
2. `docs/testing.md:63` says Layer-1 `Rules`/`State` tests live in
   `apps/gibbering_engine/test/engine/` — they actually live in
   `apps/gibbering_tales_web/test/engine/` (`apps/gibbering_engine/test/`
   has no `engine/` subdirectory).
3. `docs/workflow.md:159` references `MEMORY.md`, which does not exist
   anywhere in the repo.
4. `.claude/skills/verify/SKILL.md` says "No headless browser tooling is
   installed (no Playwright/Wallaby)". True for the default
   `docker compose up` path, but incomplete: `compose.yaml` has an opt-in
   `smoke` profile with a Playwright service, and `test/smoke/` has 6
   tracked files (`package.json`, `playwright.config.ts`,
   `screenshots/.gitkeep`, `auth.spec.ts`, `campaign.spec.ts`,
   `characters.spec.ts`). Soften the line to mention the smoke profile
   exists as an alternative (see also #63, which scopes making this
   suite real).
5. CLAUDE.md / `docs/dev-setup.md` say "no `.env` file needed" (accurate
   for the documented Docker Compose workflow — `compose.yaml` has no
   `env_file:` directive, all dev vars are inlined). `.env.example`'s own
   header says "Copy to .env — defaults match compose.yaml out of the
   box," which is confusing/unused given the above, and its
   `DATABASE_URL` even uses the Docker-only hostname `db`. Resolve by
   either clarifying `.env.example`'s purpose (e.g. for a non-Docker path,
   if one is ever supported) or removing it if genuinely unused.

**Acceptance criteria**
- [ ] All five items corrected
- [ ] A stale-ref grep pass run over `docs/` to catch any other drift
      while in there (per the review's own suggestion — this is
      effectively the project's own docs-refactor gate)
- [ ] No `mix precommit` requirement (docs-only change per CLAUDE.md)

**Source:** identified via external code review (GLM/ZAI), verified
against code before filing.
