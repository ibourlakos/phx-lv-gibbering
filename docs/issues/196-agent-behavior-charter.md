# #196 · Agent-behavior charter — docs/agent-behavior.md

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** ops, architecture

Write a dedicated agent-behavior charter, replacing CLAUDE.md's current two-line "Claude Instructions" as the fuller home for writing style, judgment, calibration, scope discipline, and confirm-before-acting rules. Adapted from `ploi-reacher`'s `.ai/guidelines/40-agent-behavior.md` (see brainstorm #36), which is largely portable framework-agnostic prose.

## What this does

- Add `docs/agent-behavior.md`, linked from CLAUDE.md's Docs TOC (pull-tier). CLAUDE.md's own "be concise" / "keep me checked" lines stay where they are — compact, specific to this user's working style, no need to move them.
- Sections to write, adapted (not copy-pasted) from ploi-reacher, with Laravel specifics stripped:
  - **Writing style** — no em-dashes, no rule-of-three padding, no opening flattery/agreement theater, lead with the answer before caveats.
  - **Judgment** — flag problems noticed outside current task scope (security holes, races, architectural issues) rather than silently ignoring or silently fixing them.
  - **Calibration** — distinguish verified / believed / guessed explicitly in the words used; never state a guess as fact.
  - **Scope** — "no drive-by cleanup": report noticed fixes, don't bundle them into unrelated work, including in docs.
  - **Confirm-before-acting gate list** — a Gibbering-specific list, treated as a living starting point rather than a rigid rule (see note below on avoiding friction):
    - git commit/push → pointer to `docs/git-policy.md`, not restated here
    - destructive OTP process actions (stopping/killing a live `SceneServer` etc.)
    - deleting a brainstorm or issue file
    - Docker volume/container prune
    - editing `compose.yaml` env vars
    - widening any future subagent's write scope
- The charter should point at `docs/git-policy.md` and `docs/workflow.md` for commit/branch conventions and path selection rather than restating them.
- State explicitly that the gate list is expected to evolve — loosening/removing an item is as legitimate an outcome as tightening one, if an item turns out to just add friction without preventing a real mistake. Phrase each gated item around genuinely irreversible or outward-facing actions, not routine reads/edits, to avoid the list becoming overly strict.
- State explicitly that the charter defers to `docs/workflow.md` for process/path selection (e.g. Path [G] docs-only skipping `mix precommit`) and only adds an action-level confirmation layer on top — no contradiction with existing standing authorizations in workflow paths.

## Background

See brainstorm #36 (`docs/brainstorming/36-ai-memory-hygiene-from-ploi-reacher.md`) for full context and the settled Decisions table this issue is derived from.

## Acceptance criteria

- [ ] `docs/agent-behavior.md` written with the five sections above, linked from CLAUDE.md's Docs TOC
- [ ] Confirm-before-acting gate list drafted, framed as a living/evolving list scoped to irreversible or outward-facing actions
- [ ] Charter explicitly defers to `docs/git-policy.md` and `docs/workflow.md` rather than duplicating their content
- [ ] CLAUDE.md's existing "be concise" / "keep me checked" lines retained as-is, not moved
