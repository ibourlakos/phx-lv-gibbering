# #88 · Game content type taxonomy and upsert workflow
**Status:** open
**Opened:** 2026-06-06
**Priority:** medium
**Tags:** discovery, architecture, gameplay

Define the canonical list of game content types and map the full change surface required when upserting each one.

Content types under consideration: races, classes, subclasses, character backgrounds, spells, active effects, abilities, items (weapons/consumables/armor/clothing), static maps (dimensions, look/feel), map decorations (rocks, buildings, trees), interactive map objects (doors, boxes), monsters, notable individuals, event visual effects, appearance components.

For each type, the upsert workflow touches: DB schema and migration, seed and test data, derived/cached data, appearance visuals (per style), player/DM interface (new choices surfaced in creation or prep), rendering requirements, testing routines, and any game/scene state implications.

The output of this issue is a reference document (or structured discovery notes) that future content work can follow. It also defines what a "content slot" looks like in the multi-style appearance system (#99).

**Acceptance criteria**
- [ ] All game content types enumerated with a brief definition of each
- [ ] For each type: checklist of layers touched during upsert (schema, seed, appearance, UI, rendering, tests)
- [ ] Multi-style appearance slot defined: which types need per-style appearance records, and what fields each appearance record must carry
- [ ] Open questions from brainstorm #11 answered or explicitly deferred with rationale
- [ ] Document committed to `docs/` or equivalent reference location
