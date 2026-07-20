# #181 · `GibberingTales.CatalogueTest` conflicts with seeded test DB state

**Status:** open
**Opened:** 2026-07-20
**Priority:** medium
**Tags:** bug, ops

`mix precommit` fails non-deterministically depending on whether the test database
has been seeded, because two groups of tests in `gibbering_tales` assume opposite
states:

- `GibberingTales.CatalogueTest` (`apps/gibbering_tales/test/gibbering_tales/catalogue/catalogue_test.exs`)
  asserts against an **unseeded** DB — e.g. `get_race("tiefling") == nil`, and calls
  `insert_race("dwarf")` expecting no existing row — so it fails with
  `Ecto.ConstraintError` (`races_pkey` / `classes_pkey` unique violations) once
  `apps/gibbering/priv/repo/seeds.exs` has run against that DB.
- `GibberingTales.Catalogue.CacheTest`, `CharactersLiveTest`, and `LobbyLiveTest`
  depend on `GibberingTales.Catalogue.Cache` (`apps/gibbering_tales/lib/gibbering_tales/catalogue/cache.ex`),
  which loads its ETS tables once at application boot straight from the DB. If the
  test DB is **unseeded** at boot, the cache stays empty for the whole test run and
  these fail (`MatchError` on `[race | _] = Cache.list_races()`, `KeyError` on
  `race.key`, class `<select>` options empty in LiveView tests, `KeyError` on
  `:base_hp` in `lobby_live.ex:117`).

Confirmed via `mix test apps/gibbering_tales/test/gibbering_tales/catalogue/catalogue_test.exs`
on `main` (pre-dating #180): 5 of 7 tests fail against a DB seeded via
`mix ecto.setup`, and the Cache-dependent suites fail symmetrically against a bare
`ecto.create && ecto.migrate` DB. This is a pre-existing gap, not a regression from
any specific branch — the project's `test` alias (`ecto.create --quiet`,
`ecto.migrate --quiet`, `test`) never seeds, so CI/local behavior differs based on
whatever `mix ecto.setup`/`mix ecto.reset` was last run against that DB, which
[docs/testing.md](../testing.md) does not currently call out.

## Acceptance criteria

- [ ] Decide and document the intended test DB contract for `gibbering_tales` (seeded
      vs. unseeded) in `docs/testing.md`
- [ ] `CatalogueTest` and the `Cache`-dependent suites no longer contradict each
      other — either by giving `CatalogueTest` its own isolated fixtures instead of
      relying on global DB emptiness, or by having the `test` alias seed
      deterministically before the suite runs
- [ ] `mix precommit` passes reproducibly regardless of prior `ecto.setup`/`ecto.reset`
      history on the test DB
