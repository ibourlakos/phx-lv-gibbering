# #117 · Architecture doc: document Gibbering.Events as Published Language registry

**Status:** closed
**Opened:** 2026-06-09
**Closed:** 2026-06-10
**Priority:** low
**Tags:** architecture

`docs/architecture.md` needs to be updated to reflect the decisions from brainstorm #15:

1. Document `Gibbering.Events.*` as the Published Language registry — the shared artifact owned by no single bounded context.
2. Show the sub-namespace layout: `Gibbering.Events.Scene.*`, `Gibbering.Events.Notification.*`, `Gibbering.Events.Campaign.*` (future), and `Gibbering.Events.EventBatch`.
3. Note the coexist transition state: `{:state_updated, state}` remains on the game topic as a Web Adapter convenience projection pending LiveView migration.
4. Reference brainstorm #15 decisions and issue #114 (struct definitions).

**References:**
- Brainstorm #15
- Issue #114
- `docs/papers/polytope-architecture.md` §3.2, §8.5

**Acceptance criteria**
- [ ] `docs/architecture.md` has a "Published Language registry" section naming `Gibbering.Events.*` and its sub-namespaces
- [ ] The coexist transition status of `{:state_updated, state}` is documented
- [ ] The notification topic split (`"notifications:#{campaign_id}"`) is documented
