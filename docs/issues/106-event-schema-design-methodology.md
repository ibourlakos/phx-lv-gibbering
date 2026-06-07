# #106 · Event schema design methodology — Published Language mini-cycle

**Status:** open
**Opened:** 2026-06-07
**Priority:** medium
**Tags:** architecture, discovery

The polytope architecture establishes the event schema registry (Published Language) as the most important contract in the system — a schema change is a system-wide API breaking change, not a local one. As of the treatise (`docs/papers/polytope-architecture.md`, §7), the methodology is described conceptually. This issue tracks operationalizing it for this codebase.

The required mini-cycle is: Event Storming (discovery) → schema specification → consumer-driven contract validation → versioning policy enforcement. Each step needs concrete workflow artifacts:

- An Event Storming output format (even if done informally as a brainstorming document)
- A canonical event struct template with the required envelope fields (`event_id`, `event_type`, `occurred_at`, `schema_version`, `causation_id`, `correlation_id`, `payload`)
- A convention for where event schemas live in the codebase and how they are named
- A consumer-driven contract testing approach suited to ExUnit (or a decision to defer this until the bus port is implemented)
- A versioning and deprecation policy for `schema_version` bumps and breaking changes

This issue is a prerequisite for any formal event store or persistent event log implementation. It informs the Published Language parallel of the Integration dimension.

**References**
- `docs/papers/polytope-architecture.md` §3.2 (Published Language as central contract), §6 (compound bus), §7 (schema design methodology)
- Issue #32 (DM override event schema) — a concrete instance of this problem

**Acceptance criteria**
- [ ] An event envelope struct (or convention) is defined and documented, covering the required fields
- [ ] A convention for schema versioning is documented (where versions live, what constitutes a breaking change, how migration windows work)
- [ ] A consumer-driven contract testing approach is defined for this stack (ExUnit-based or deferred with justification)
- [ ] An Event Storming output format is established (at minimum: a brainstorming document listing domain events, their producers, and their known consumers for the current scene context)
- [ ] The schema design workflow is referenced from `docs/workflow.md` or `docs/architecture.md` as the step that precedes any bus or event store implementation
