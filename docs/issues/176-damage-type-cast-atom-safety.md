# #176 · `DamageType.cast/1` leaks atoms on unknown input
**Status:** open
**Opened:** 2026-07-03
**Priority:** low
**Tags:** bug, architecture

`GibberingTales.DamageType.cast/1` calls `String.to_atom(string)` *before* checking
membership in `@valid`. Every unknown string interns a new atom; atoms are never
garbage-collected, so unbounded caller input (e.g. future UGC content, ingestion
pipelines) can grow the atom table until the VM dies. Same pattern to watch for in
future `cast`-style helpers.

Safe form — compile-time lookup map, no atom creation on the miss path:

```elixir
@lookup Map.new(@valid, &{Atom.to_string(&1), &1})
def cast(string) when is_binary(string) do
  case @lookup do
    %{^string => atom} -> {:ok, atom}
    _ -> {:error, :unknown}
  end
end
```

**Acceptance criteria**
- [ ] `cast/1` no longer calls `String.to_atom/1`
- [ ] Behaviour unchanged for valid and invalid inputs (existing tests pass; add a test asserting no atom is created for unknown input if practical)
- [ ] `mix precommit` passes
