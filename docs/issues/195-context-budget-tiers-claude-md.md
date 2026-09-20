# #195 · Context-budget tiers for CLAUDE.md — push-full/push-head/pull, enforced size cap

**Status:** closed
**Opened:** 2026-09-20
**Closed:** 2026-09-20
**Priority:** medium
**Tags:** ops, architecture

Give CLAUDE.md an explicit size discipline instead of letting it grow unbounded. Adapted from `ploi-reacher`'s `.ai/rules/context-budget-tiers.md` (see brainstorm #36), which formalizes three tiers for AI-facing docs:

- **push-full** — loads every session verbatim. CLAUDE.md itself. Byte-capped, enforced by a test.
- **push-head** — only a short description/pointer loads every session; the full body loads on demand (skill descriptions vs. bodies, doc TOC one-liners).
- **pull** — unbounded; loaded only when an agent recognizes the need (`docs/brainstorming/README.md`, `docs/issues/README.md`, architecture sub-docs).

## What this does

- Add a new `docs/ai-memory.md` documenting the three-tier taxonomy and an escalation order for when the cap is hit: prune stale rows → move a section to pull-tier → raise the cap with justification in the commit message (last resort, never a silent norm-bend). Link it from CLAUDE.md's Docs TOC.
- Demote two sections out of CLAUDE.md into existing pull-tier docs, replacing them with one-line pointers:
  - The brainstorming log table → moves into `docs/brainstorming/README.md` (or becomes a pointer-only line in CLAUDE.md).
  - The issue tracker's inline add/close/defer/block/cancel instructions → move into `docs/issues/README.md`.
- Add an ExUnit test asserting `CLAUDE.md`'s byte size stays under a fixed threshold, failing loudly in `mix precommit`/CI if exceeded. Set the cap at the post-demotion size + ~20% headroom (current pre-demotion size: 9,650 bytes — measure the actual post-move size when implementing and set the cap from that, not from the pre-demotion number).
- Note in `docs/workflow.md` that a CLAUDE.md edit under Path [G]/docs-only still must run the cap test, even though Path [G] otherwise doesn't require `mix precommit` — this test exists specifically to guard the file being edited.

## Background

See brainstorm #36 (`docs/brainstorming/36-ai-memory-hygiene-from-ploi-reacher.md`) for full context and the settled Decisions table this issue is derived from.

## Acceptance criteria

- [x] `docs/ai-memory.md` written: tier taxonomy + escalation order, linked from CLAUDE.md's Docs TOC
- [x] Brainstorming log table moved out of CLAUDE.md into `docs/brainstorming/README.md`; CLAUDE.md keeps a one-line pointer
- [x] Issue-tracker instructions moved out of CLAUDE.md into `docs/issues/README.md`; CLAUDE.md keeps a one-line pointer
- [x] ExUnit test added asserting CLAUDE.md stays under a measured byte cap; wired into `mix precommit`
- [x] `docs/workflow.md` Path [G] notes the cap-test exception for CLAUDE.md edits

## Outcome

CLAUDE.md: 9,650 → 3,893 bytes. Cap set at 5,000 bytes (post-demotion size + ~20% headroom). The byte-cap test lives at `apps/gibbering_tales/test/gibbering_tales/docs/claude_md_budget_test.exs`, documented as a new "meta/repo-hygiene" test category in `docs/testing.md` (no existing layer fit a doc-property assertion). Verified the test fails correctly when CLAUDE.md exceeds the cap, and passes at the current size. `mix precommit` run clean aside from pre-existing unrelated failures (`CharactersLiveTest`, `LobbyLiveTest` — confirmed present on `main` before this branch).
