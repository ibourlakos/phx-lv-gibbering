# #197 · Brainstorm lifecycle: ending states + evacuation gate script

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** ops, architecture

Tighten `docs/brainstorming/README.md`'s lifecycle with explicit ending-state vocabulary and an enforced check that decisions actually graduate out of a brainstorm file before it's deleted. Adapted from `ploi-reacher`'s issue-label discovery/brainstorm lifecycle (see brainstorm #36).

## What this does

- Add `Superseded` and `Revamped` as literal `**Status:**` values in the brainstorm file header, alongside `open`/`settled`, documented in `docs/brainstorming/README.md`'s lifecycle section:
  - `Superseded` — a newer brainstorm replaces this one outright; add a "Superseded by #N" line pointing at the replacing brainstorm; closes without full triage.
  - `Revamped` — significantly reworked mid-flight within the same file/number.
- Add an **evacuation gate**, enforced by a script, at the Close step: before a brainstorm file is deleted, the script checks that the brainstorm number is referenced somewhere in `docs/issues/` or `docs/architecture/`, refusing deletion if not. Scoped to `docs/brainstorming/` only for now — not extended to `docs/issues/` close/defer/cancel actions (left as an open question for a future brainstorm).
- No new ADR (`docs/decisions/`) layer — `docs/architecture/` remains the accepted "living doc" destination for graduated decisions in this epic. Revisit only if decisions start getting lost inside `docs/architecture/`'s edit-in-place style in practice.
- No new explicit "comments carry no authority" rule text — settled as unnecessary: authority here is already indirect (a conversational comment only matters once it updates an issue description or a brainstorm's Decisions table; the update carries authority, not the comment). No change needed to existing lifecycle language.

## Background

See brainstorm #36 (`docs/brainstorming/36-ai-memory-hygiene-from-ploi-reacher.md`) for full context and the settled Decisions table this issue is derived from.

## Acceptance criteria

- [ ] `Superseded` and `Revamped` status values documented in `docs/brainstorming/README.md`'s lifecycle section, with usage rules (Superseded-by pointer, etc.)
- [ ] Evacuation-gate script written: refuses to delete a brainstorm file at Close unless its number is referenced in `docs/issues/` or `docs/architecture/`
- [ ] Script wired into the documented Close step in `docs/brainstorming/README.md`
- [ ] No changes made to `docs/issues/` lifecycle or a new `docs/decisions/` layer — confirmed out of scope for this issue
