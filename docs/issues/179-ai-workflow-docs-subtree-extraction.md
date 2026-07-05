# #179 · Extract AI workflow docs/config into a reusable subtree

**Status:** open
**Opened:** 2026-07-05
**Priority:** low
**Tags:** discovery, architecture, ops

Explore decomposing the AI-facing process docs (`docs/workflow.md` and satellites) and `.claude/` config into a separate template repo, consumed here via `git subtree`, so the same process can be reused across other projects without copy-pasting and manually re-syncing.

## Background

`docs/workflow.md`, `docs/git-policy.md`, `docs/testing.md`, and `.claude/settings.json` mix genuinely reusable process design (the seven-path model, conventional commits, the git-add/no-commit-to-main hooks) with Gibbering-specific detail (module names, umbrella app layout, Docker test commands). `git subtree` was chosen over `git submodule` because the shared docs are expected to diverge per-project, and subtree tolerates local divergence without the detached-HEAD/sync friction submodules impose; the trade-off is that `subtree push` gets more expensive and fragile as history grows or gets rewritten (rebases/squash-merges break the sync-marker trailer subtree relies on to avoid rescanning full history) — acceptable here since the intended flow is mostly one-directional (edit template repo → `pull` into consumers).

## Open questions to settle

- **Doc reorg first:** move `docs/testing.md` and `docs/git-policy.md` under `docs/workflow/` (mirroring the existing `docs/architecture.md` + `docs/architecture/` pattern) as its own standalone docs-only commit, independent of the subtree work. `docs/legal.md` and `docs/dev-setup.md` stay top-level — broader in scope than a single workflow step.
- **Multi-location problem:** a single `git subtree add`/`pull` maps one remote branch to exactly one local prefix, and pulls the *entire* remote tree into it — it cannot fan one subtree out to both `docs/workflow/` and `.claude/`. Decide between:
  - two separate single-purpose template repos (one for workflow docs, one for Claude config) — each gets a clean 1:1 prefix mapping, at the cost of two upstreams to maintain, or
  - one template repo with `git subtree split --prefix=<dir>` run on the source side before each pull, to carve out per-destination synthetic branches — one upstream, but reintroduces per-sync ceremony.
- **Content genericization:** `workflow.md`, `testing.md`, and `git-policy.md` need their Gibbering-specific nouns (module names, `mix test` invocations, the "scopes" table) replaced with placeholders or generic phrasing before they're reusable as-is.
- **`.claude/settings.json` hooks:** the two active hooks (deny `git add -A/--all/.`, deny commits to `main`) are already generic and portable verbatim; the disabled test-on-commit hook needs its `docker compose run --rm app mix test` command turned into a placeholder.
- **New doc home:** add `docs/subtrees/<name>.md` (not `docs/workflow/subtree-sync.md` — too narrow if other subtrees get added later for unrelated reasons) documenting each subtree's remote, prefix(es), and sync commands.
- Which repo hosts the template — new repo under the same account, or reuse an existing one?

## Acceptance criteria

- [ ] Decision recorded on the multi-location subtree problem (two repos vs. split-per-pull)
- [ ] `docs/testing.md` and `docs/git-policy.md` relocated to `docs/workflow/` in a standalone commit, links updated
- [ ] Template repo created and seeded with genericized `workflow.md`, `testing.md`, `git-policy.md`, and `.claude/settings.json`/`hooks.disabled.json`
- [ ] `docs/subtrees/<name>.md` written, documenting remote(s), prefix(es), and sync commands
- [ ] This repo's copies of the extracted files converted to subtree-tracked content via `subtree add`
