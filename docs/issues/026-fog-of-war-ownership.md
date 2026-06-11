# #26 · Fog-of-war ownership: ruleset or engine?
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-11
**Priority:** medium
**Tags:** discovery, architecture, rendering

Fog of war — which tiles are visible to which players — sits at the intersection of rules and rendering. It is unclear whether the Ruleset or the Engine should own the visibility calculation.

Options:
- **Engine owns it** — engine provides a generic line-of-sight primitive; rulesets configure range/parameters. Keeps rulesets thin.
- **Ruleset owns it** — ruleset implements a `visible_tiles/2` callback; engine just masks. Allows exotic rulesets (e.g. Darkvision, Blindsight).
- **Split** — engine owns the SVG mask layer, ruleset owns the predicate.

Currently no fog of war is implemented, so this can be designed before the first implementation.

**Acceptance criteria**
- [x] Decision written: which module owns fog calculation and what the contract looks like
- [x] Decision reflected in `Gibbering.Ruleset` behaviour (callback or absence of one)
- [x] First fog implementation follows the decided ownership model
