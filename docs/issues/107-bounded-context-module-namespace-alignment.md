# #107 · Bounded context module namespace alignment

**Status:** open
**Opened:** 2026-06-07
**Priority:** medium
**Tags:** discovery, architecture

The polytope treatise (`docs/papers/polytope-architecture.md`) names eight bounded contexts precisely. The current module map in `docs/architecture.md` uses a layered naming convention (Engine, Data, Web) that does not correspond to the polytope decomposition. Before any significant new module work starts, the canonical Elixir namespace for each bounded context must be decided and documented.

Contexts surfaced by the treatise that need a canonical home:

| Bounded context | Polytope parallel | Current module(s) | Decision needed |
|---|---|---|---|
| Scene | Behavioral (scene machine) | `Gibbering.Engine.*` | Rename to `Gibbering.Scene.*`? |
| Rules Engine | Structural (core domain) | `Gibbering.Ruleset`, `Gibbering.Rulesets.DnD5e.*` | Already reasonable; confirm |
| Content Catalogue | Structural (core domain) | `Gibbering.Data.*` | Rename to `Gibbering.Catalogue.*`? |
| Campaign Lifecycle | Structural (supporting) | `Gibbering.Campaigns.*` | Reasonable; confirm |
| Identity & Authorization | Structural (supporting) | `Gibbering.Accounts.*` | Reasonable; confirm |
| Observability | Structural (generic) | `Gibbering.MetricsStore`, LiveDashboard | Namespace? |
| Notification | Structural (generic) | Scattered (PubSub calls, whispers) | Needs a home |
| Bus (meta-hexagon) | Integration | `Phoenix.PubSub` direct calls | `Gibbering.EventBus` (see #108) |

The decision also determines the correct name for the module-level rename of `GameServer` → whatever the Scene context's primary process is called (SceneServer is the treatise term; the namespace must be settled first).

**References**
- `docs/papers/polytope-architecture.md` §3.1 (bounded context graph), §8 (five dimensions applied), §3.3 (bus as meta-hexagon)
- `docs/architecture.md` (current module map — to be updated)
- Issue #108 (EventBus behaviour, blocked by this decision)

**Acceptance criteria**
- [ ] Canonical module namespace is decided for each bounded context above and recorded in `docs/architecture.md`
- [ ] `docs/architecture.md` module map is updated to reflect the polytope model, not the old layered naming
- [ ] Any renames that follow from this decision are opened as separate implementation issues (or folded into a single refactor issue if the scope is bounded)
- [ ] The Notification context is assigned a namespace (even if it remains a thin wrapper over PubSub for now)
