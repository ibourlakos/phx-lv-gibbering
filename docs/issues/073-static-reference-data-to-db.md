# #73 · Migrate static reference data to DB tables

**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** architecture, ops

`Gibbering.Data.{Races, Classes, Spells}` are currently hardcoded in-memory Elixir modules. Admin catalogue CRUD ([#71](071-admin-catalogue-crud.md)) requires these to be writable DB tables so editors can update entries without a code deploy.

This is a prerequisite for [#71](071-admin-catalogue-crud.md).

The in-memory modules become the seed source — they populate the DB on first setup and serve as the canonical reference for tests. At runtime the engine reads from the DB (via a cached context, not raw `Repo` calls on the hot path).

**Acceptance criteria**
- [ ] Migrations create `races`, `classes`, `spells` tables with columns matching the current in-memory map shapes (plus `key` string PK, `inserted_at`, `updated_at`)
- [ ] `Data.Races`, `Data.Classes`, `Data.Spells` modules converted to seed sources — `mix ecto.setup` populates the tables from them
- [ ] Ecto schemas and context functions defined for each catalogue type (at minimum `list/0`, `get_by_key/1`)
- [ ] Engine and lobby code updated to read from DB context instead of in-memory module — wrapped in an ETS-backed cache to avoid hot-path `Repo` calls
- [ ] `docs/data-model.md` updated to document the new tables
- [ ] Existing tests updated; new tests cover `get_by_key/1` for each catalogue type
