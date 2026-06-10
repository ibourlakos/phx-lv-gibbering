# #108 · EventBus behaviour: port and adapters

**Status:** open
**Opened:** 2026-06-07
**Priority:** medium
**Tags:** architecture

The polytope treatise (§3.3) establishes that the event bus must be encapsulated behind its own port — a behaviour definition — exactly as `Gibbering.Ruleset` is a port for the rules context. Currently `Phoenix.PubSub` is called directly at every broadcast and subscription site. This makes the bus adapter leak into every bounded context, coupling all contexts to a specific transport mechanism and making deterministic testing impossible without running PubSub.

The required structure:

```
Gibbering.EventBus          ← behaviour (the port)
├── Gibbering.EventBus.PubSub   ← adapter: Phoenix.PubSub (production)
└── Gibbering.EventBus.Local    ← adapter: synchronous in-memory (tests)
```

Swapping between adapters must require no change to any bounded context module. The bus adapter is selected at the application configuration level (or passed as a dependency to the relevant supervisor).

Namespace decision (#107) is closed: the behaviour lives at `Gibbering.EventBus`. Event types are defined in `Gibbering.Events.*` (see #119 — struct definitions must land before full implementation). The behaviour must include a `broadcast_batch/2` callback to support the `%EventBatch{}` pattern from brainstorm #15.

**References**
- `docs/papers/polytope-architecture.md` §3.3 (bus as meta-hexagon, fractal self-similarity), §6.3 (vertical bus stack), §10.3 (deployment is an adapter decision)
- Issue #107 (module namespace — closed)
- Issue #109 (compound bus command/event separation — closed)
- Issue #119 (event struct definitions — complete before implementing broadcast_batch)
- Brainstorm #15 (event schema decisions)


**Acceptance criteria**
- [ ] `Gibbering.EventBus` behaviour defined with at minimum: `broadcast/2`, `broadcast_batch/2`, `subscribe/1`, `unsubscribe/1`
- [ ] `Gibbering.EventBus.PubSub` adapter implemented and wired as the default
- [ ] `Gibbering.EventBus.Local` synchronous adapter implemented for use in tests (no process spawning required)
- [ ] All cross-context event broadcasts in the codebase go through the behaviour, not `Phoenix.PubSub` directly
- [ ] `docs/architecture.md` updated to show the bus as a bounded context with a port and adapters
- [ ] Existing tests continue to pass; new tests use the Local adapter by default
