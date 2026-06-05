# #15 · Document `stats: map()` tradeoffs for entity stats

**Status:** open
**Opened:** 2026-06-04
**Priority:** low
**Tags:** architecture

The `stats: map()` field on entities is an intentional flexibility choice confirmed in `02-splitting-the-grimoire.md` and `03-the-proving-grounds.md`. The tradeoffs are real but unacknowledged anywhere:

**What it costs:**
- Dialyzer cannot verify stat key usage — a typo like `entity.stats["strenght"]` is silent at runtime.
- Ecto changeset validation doesn't apply to the inner map structure.
- Ruleset bugs that misread a stat key return `nil` and propagate silently (e.g. `nil + 3` raises a runtime error far from the source).

**What it buys:**
- Any ruleset can store its own stat shape without touching the engine's entity schema.
- D&D, Cyberpunk, homebrew systems coexist in the same data layer.

This tradeoff should be documented in `docs/architecture.md` so contributors understand why the map is intentionally untyped and don't try to "fix" it with a typed struct — or introduce a worse version of the same problem.

**Acceptance criteria**
- [ ] `docs/architecture.md` has a note explaining the `stats: map()` design decision, its costs, and mitigations (e.g., ruleset-level validation at the behaviour boundary)
- [ ] At minimum, each ruleset should validate required stat keys at session start and fail fast rather than propagating `nil`
