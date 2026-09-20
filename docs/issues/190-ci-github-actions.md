# #190 · No CI — add GitHub Actions running `mix precommit`

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** ops, architecture

No `.github/workflows` directory exists; every gate (legal, architecture,
precommit) depends on a human or agent voluntarily running it locally.
This project has notably strong AI-agent governance (workflow paths,
hooks, docs discipline) but no server-side enforcement layer behind it —
the governance assumes an executor that never skips a step, which isn't a
safe assumption.

A GitHub Actions job running `mix precommit` (via the existing Docker
image, so it matches local dev exactly — no separate CI-only setup) would
have caught #181's test DB seed contract issue, and would catch future
doc/code drift and regressions automatically rather than at review time.

Related: #63 (Playwright smoke test suite + Docker environment) is a
separate, larger scope (browser-driven smoke tests); this issue is
specifically about running the existing `mix precommit` alias on every
push/PR, independent of #63.

**Acceptance criteria**
- [ ] `.github/workflows/ci.yml` (or similar) runs `mix precommit` inside
      the project's existing Docker image on push/PR to any branch
      (or at minimum PRs targeting `main`)
- [ ] DB service (Postgres) provisioned in CI matching `compose.yaml`'s
      version/config
- [ ] CI passing is documented as a merge expectation in
      `docs/git-policy.md` or `docs/workflow.md`
- [ ] `mix precommit` passes locally before merging this issue's own PR

**Source:** identified via external code review (GLM/ZAI), verified
against code before filing.
