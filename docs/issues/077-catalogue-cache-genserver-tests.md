# #77 · Catalogue.Cache GenServer tests
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** medium
**Tags:** architecture, ops

`Gibbering.Catalogue.Cache` sits at 30% coverage. The untested paths are:

- `reload!/0` — triggers ETS table reload from DB; the happy path and the crash path (empty table)
- `list_backgrounds/0`, `list_classes/0`, `list_races/0`, `list_spells/0` — ETS reads that return all rows of a given type

These require a running GenServer and seeded DB rows. They should use `DataCase` and start a named test instance of the Cache, or rely on the existing `test` start-up configuration.

**Acceptance criteria**
- [x] Each `list_*` function is tested against seeded catalogue rows
- [x] `reload!/0` is tested: after a reload the `list_*` functions return fresh data
- [x] Tests use the app-supervised Cache with `DataCase, async: false` (shared sandbox allows Cache process DB access during reload)
- [x] Coverage on `Gibbering.Catalogue.Cache` reaches ≥ 90%
