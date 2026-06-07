# #112 · Bounded context map document

**Status:** open
**Opened:** 2026-06-07
**Priority:** low
**Tags:** discovery, architecture

The polytope treatise establishes the bounded context graph as the central structural artifact of the system. Vernon (2013) proposes the *context map* as the companion document to a DDD design: a record of all bounded contexts, how they relate to each other, and which integration pattern is used at each seam (Conformist, Customer-Supplier, Anti-Corruption Layer, Published Language, Shared Kernel, Open Host Service).

This project has no such document. `docs/architecture.md` lists modules; the polytope treatise names contexts conceptually. Neither provides a working relationship map that is maintained as the design evolves and can be used to:
- Make integration pattern choices explicit (e.g. Scene → Rules Engine: Customer-Supplier; Campaign → Identity: Conformist)
- Surface ACL obligations (which contexts translate incoming events before consuming them)
- Identify seams where the Published Language is the integration mechanism (all event bus subscriptions)
- Diagnose coupling violations during code review (a context import that bypasses the map)

The context map is a living document, not a one-time artifact. It should be updated whenever a new bounded context is introduced, a seam changes integration pattern, or a known violation is fixed.

**References**
- `docs/polytope-architecture.md` §3.1, §8 (bounded context graph and dimensions), §2.2 (DDD context map)
- Vernon (2013) — *Implementing Domain-Driven Design*, Chapter 3 (Context Maps)
- Issue #107 (namespace alignment — must be settled before the map can name modules precisely)

**Acceptance criteria**
- [ ] A `docs/context-map.md` document exists listing all bounded contexts with their canonical module namespace (from #107)
- [ ] Each inter-context relationship names its integration pattern at the seam
- [ ] ACL obligations are called out: which contexts wrap incoming bus events in translation layers
- [ ] All Published Language seams (event bus subscriptions) are enumerated
- [ ] The document is linked from `docs/architecture.md`
- [ ] A convention is established for how to update the map when a new context or seam is introduced
