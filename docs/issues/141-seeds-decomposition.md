# #141 · Decompose seeds.exs into per-concern sub-files

**Status:** open
**Opened:** 2026-06-19
**Priority:** low
**Tags:** ops, architecture

`priv/repo/seeds.exs` is 1074 lines across seven distinct concerns that share no
dependencies on each other except users → campaigns. The file will keep growing as
more campaigns and catalogue entries are added.

Decompose it into a thin orchestrator + self-contained sub-files:

```
priv/repo/seeds.exs                        ← orchestrator (~20 lines)
priv/repo/seeds/
  catalogue.exs                            ← races, classes, spells, monsters (idempotent)
  users.exs                                ← dev user accounts; returns %{dm:, alice:, bob:, charlie:}
  support_user.exs                         ← admin support user (idempotent)
  styles.exs                               ← DST Style + Appearance records (idempotent)
  campaigns/
    duskwood_crossing.exs                  ← Campaign 1: map, tiles, heroes, monsters, objects
    sunken_crypt.exs                       ← Campaign 2: map, tiles, heroes, monsters, objects
```

The orchestrator runs the wipe block and threads context between files using return
values (e.g. `users.exs` returns a map of user structs that campaign files receive as
an argument). Each sub-file owns its own `alias` declarations and is independently
readable.

**Granularity decision:** stop at per-campaign, not per-entity. Heroes/monsters/objects
within a campaign share `campaign_id` context and form a cohesive scene — splitting
them further fragments meaningful scene design into many tiny files.

**Acceptance criteria**
- [ ] `priv/repo/seeds.exs` is a thin orchestrator (≤ 30 lines, no inline data)
- [ ] Sub-files live under `priv/repo/seeds/` in the structure above
- [ ] Each sub-file has its own `alias` declarations and is independently readable
- [ ] Context flows top-down via return values, not global state
- [ ] `docker compose exec app mix ecto.setup` succeeds end-to-end
- [ ] `docker compose exec app mix ecto.reset` succeeds end-to-end
- [ ] No functional change to seeded data
