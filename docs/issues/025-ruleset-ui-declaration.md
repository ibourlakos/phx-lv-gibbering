# #25 · Ruleset UI declaration
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-11
**Priority:** medium
**Tags:** discovery, architecture

How does a Ruleset module tell the engine what UI controls to render for a given game state? Specifically: action buttons (Attack, Cast Spell, End Turn), stat panels (HP bar, spell slots, conditions), and any ruleset-specific overlays.

Current state: the DnD5e ruleset is hardcoded into the LiveView template. There is no contract between a Ruleset and the renderer for declaring what UI to show.

**Acceptance criteria**
- [x] A design decision is written (callback on the behaviour, a data struct returned, a component convention, or something else)
- [x] The chosen approach is reflected in `Gibbering.Ruleset` behaviour definition
- [x] DnD5e ruleset implements it and the UI renders without hardcoded template conditionals
