# #77 · Catalogue.Cache GenServer tests
**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** architecture, ops

`Gibbering.Catalogue.Cache` sits at 30% coverage. The untested paths are:

- `reload!/0` — triggers ETS table reload from DB; the happy path and the crash path (empty table)
- `list_backgrounds/0`, `list_classes/0`, `list_races/0`, `list_spells/0` — ETS reads that return all rows of a given type

These require a running GenServer and seeded DB rows. They should use `DataCase` and start a named test instance of the Cache, or rely on the existing `test` start-up configuration.

**Acceptance criteria**
- [ ] Each `list_*` function is tested against seeded catalogue rows
- [ ] `reload!/0` is tested: after a reload the `list_*` functions return fresh data
- [ ] Tests start an isolated Cache process (not the app-level supervised one) or use the supervised one only if test isolation is maintained
- [ ] Coverage on `Gibbering.Catalogue.Cache` reaches ≥ 90%
