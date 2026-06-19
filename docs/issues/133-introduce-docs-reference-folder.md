# #133 · Introduce `docs/reference/` for vocabulary and reference documents

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-19
**Priority:** low
**Tags:** architecture

Vocabulary and reference documents (closed-vocabulary definitions, content
taxonomy checklists, entity state tables) are currently scattered: one lives
in `docs/architecture/`, one in the `docs/` root. As this set grows (entity
states, action vocabulary, event types) the inconsistency compounds.

Introduce `docs/reference/` as a top-level sibling of `docs/architecture/`
for all canonical domain definitions — documents that describe *what things
are called and what states they can be in*, as opposed to *how the system is
built* (architecture) or *how to operate it* (dev-setup, workflow, etc.).

`predicate-vocabulary.md` stays in `docs/architecture/` — it is a code
contract (evaluator signature + closed predicate set), not a domain glossary.

**Acceptance criteria**
- [x] `docs/reference/` directory exists
- [x] `docs/game-content-taxonomy.md` moved to `docs/reference/game-content-taxonomy.md`
- [x] `docs/architecture.md` TOC updated: existing architecture table unchanged; new Reference table added pointing to `docs/reference/`
- [x] All inbound links to `docs/game-content-taxonomy.md` updated to the new path
