# #25 · Ruleset UI declaration
**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** discovery, architecture

How does a Ruleset module tell the engine what UI controls to render for a given game state? Specifically: action buttons (Attack, Cast Spell, End Turn), stat panels (HP bar, spell slots, conditions), and any ruleset-specific overlays.

Current state: the DnD5e ruleset is hardcoded into the LiveView template. There is no contract between a Ruleset and the renderer for declaring what UI to show.

**Acceptance criteria**
- [ ] A design decision is written (callback on the behaviour, a data struct returned, a component convention, or something else)
- [ ] The chosen approach is reflected in `Gibbering.Ruleset` behaviour definition
- [ ] DnD5e ruleset implements it and the UI renders without hardcoded template conditionals
