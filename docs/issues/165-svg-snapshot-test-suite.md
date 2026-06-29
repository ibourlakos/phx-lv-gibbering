# #165 · SVG snapshot test suite for SpriteCompositor

**Status:** open
**Opened:** 2026-06-29
**Priority:** low
**Tags:** ops, rendering

`SpriteCompositor` is currently tested with brittle string matching (`assert result =~ "fill=\"red\""`). Add an approval-style snapshot test suite: render known entity/appearance combos, store the expected SVG in fixture files, assert exact match. A failing test signals an intentional or accidental appearance change and requires deliberate approval.

Depends on #153 (SVG data attributes) — snapshots are more stable and readable once semantic attributes are present.

**Reference inputs to cover (at minimum):**
- A biped entity at full HP, no conditions
- A biped entity at ≤ 25% HP (HP bar in warning state)
- A biped entity with one condition badge
- A biped entity with selection ring active
- A non-biped archetype (e.g., quadruped or aberration) at full HP

**Implementation notes:**
- Store reference SVGs in `test/fixtures/snapshots/<slug>.svg`
- Test module: `test/gibbering/engine/sprite_compositor_snapshot_test.exs`
- To update: regenerate the fixture file and commit it — the diff is the approval record

**Acceptance criteria**
- [ ] `test/fixtures/snapshots/` contains ≥ 5 reference SVG files
- [ ] `test/gibbering/engine/sprite_compositor_snapshot_test.exs` asserts each fixture exactly
- [ ] Test names clearly describe the scenario each snapshot represents
- [ ] `mix precommit` passes
