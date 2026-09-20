# #186 · Fresh-clone boot crash-loop: `Catalogue.Cache` queries before migrations run

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** bug, ops

The documented setup flow (`docs/dev-setup.md`) runs `docker compose up
--build` (step 3) before `docker compose exec app mix ecto.setup`
(step 4, in a second terminal). On a genuinely fresh clone with a fresh DB
volume, this crash-loops the app container.

`GibberingTales.Application` starts children in order `[Repo,
Catalogue.Cache]`. `Catalogue.Cache.init/1` synchronously calls `load()`,
which queries `races`/`classes`/etc. tables via `Repo.all`. Those tables
don't exist until `ecto.setup` has run. `compose.yaml`'s `app` service
only waits on `db: condition: service_healthy`, and the db healthcheck is
just `pg_isready`, which succeeds on an empty, unmigrated database — there
is no gate on migrations having actually run.

Result: `Catalogue.Cache.init/1` raises a Postgrex undefined-table error,
which crashes the GenServer's `init/1`, which the `one_for_one` supervisor
treats as a startup failure, restarting the whole app.

Reproduced live (external review) against the documented setup order.

**Acceptance criteria**
- [ ] Either: `Catalogue.Cache.init/1` tolerates missing tables (lazy load
      / retry with backoff instead of crashing), or the documented setup
      order in `docs/dev-setup.md` is changed so migrations always run
      before first app boot (e.g. an init container / entrypoint step)
- [ ] Fresh clone + fresh DB volume + documented setup steps, in order,
      no longer crash-loops
- [ ] `docs/dev-setup.md` updated to match whichever fix is chosen
- [ ] `mix precommit` passes

**Note:** distinct from #181 (test DB seed-state contract causing
non-deterministic `mix test` failures) — this is the app process crashing
on boot against a genuinely unmigrated DB, not test flakiness. Related but
not duplicate.

**Source:** identified via external code review (GLM/ZAI), verified
(and reproduced) before filing.
