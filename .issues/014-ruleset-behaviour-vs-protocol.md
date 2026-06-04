# #14 · `Gibbering.Ruleset`: behaviour vs protocol

**Status:** open
**Opened:** 2026-06-04
**Priority:** medium
**Tags:** discovery, architecture

`02-splitting-the-grimoire.md` leaves this explicitly open. The choice has concrete consequences:

- **`behaviour`** — callbacks are implemented as module-level functions; dispatch is a runtime module reference (`ruleset.on_move_requested(...)`). Simple, idiomatic Elixir. Rulesets are compile-time modules. External hex packages can implement the behaviour. Works well for the current design.
- **`protocol`** — dispatch is structural, based on the data type passed. Enables polymorphism without needing to hold a module reference in state. More useful when the *data* varies in type rather than the *module* that handles it. Overkill for the current `GameServer` pattern where the ruleset module is already stored as a field.

The decision must be locked before the Ruleset split is implemented (see #3), because changing from `behaviour` to `protocol` after the fact requires restructuring all call sites.

Recommendation: **`behaviour`** — it matches the current dispatch pattern exactly and protocol adds no value here since rulesets are whole-module strategies, not per-value polymorphism.

**Acceptance criteria**
- [ ] Decision recorded here with rationale
- [ ] `Gibbering.Ruleset` `@behaviour` defined and `@callback`s documented with proper typespecs
- [ ] `DnD5e` module declares `@behaviour Gibbering.Ruleset` and implements all callbacks
- [ ] Decision reflected in `docs/architecture.md`
