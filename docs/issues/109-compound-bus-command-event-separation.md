# #109 · Compound bus: command/event bus separation

**Status:** closed
**Opened:** 2026-06-07
**Closed:** 2026-06-09
**Priority:** medium
**Tags:** discovery, architecture

The polytope treatise (§6.2, §6.4) formalizes the compound bus as B = (C, E):
- **C** (command bus): fan-out = 1, addressed, synchronous or acknowledged. Implemented by `GenServer.call/cast`.
- **E** (event bus): fan-out ∈ [0, ∞), unaddressed broadcast, async. Implemented by PubSub.
- Lc ∩ Le = ∅ — command types and event types are disjoint sets; nothing crosses both buses.

The current codebase does not enforce this distinction. Some cross-context communication uses direct module calls (correct for commands), some uses PubSub (correct for events), and some may be ambiguous. The diagnostic rule from §6.4 applies: if a bus-like structure appears inside a bounded context, it is a symptom — either the context has grown too large, or the communication should be a direct function call.

This issue tracks: (1) auditing all cross-context communication, (2) classifying each as command or event, and (3) fixing any misclassifications or opening sub-issues for those that require significant refactoring.

**References**
- `docs/papers/polytope-architecture.md` §6.2 (command vs event bus), §6.4 (compound bus definition and diagnostic rule)
- Issue #108 (EventBus behaviour — the implementation of E)
- Issue #110 (SceneServer single-writer — follows from this classification)

**Acceptance criteria**
- [ ] All existing cross-context calls are audited and classified as command (C) or event (E)
- [ ] The boundary rule is documented in `docs/architecture.md`: no bounded context crosses another's boundary via a direct module import; all cross-context interaction belongs to C or E
- [ ] Any misclassified communication is either fixed inline or tracked as a sub-issue
- [ ] The distinction between C and E is visible in module docs or a section of `docs/architecture.md` so it is enforceable during code review
