# #113 · CQRS read model formalization

**Status:** open
**Opened:** 2026-06-07
**Priority:** low
**Tags:** discovery, architecture

The polytope treatise (§9, Temporal dimension: CQRS) notes that LiveView socket assigns are *informal* read models — CQRS makes this explicit. Currently the distinction between write-side state (owned by SceneServer) and read-side state (consumed by adapters) is not enforced structurally. SceneServer broadcasts its full state struct and LiveView unpacks it ad hoc.

The formal model:
- **Write side (C):** SceneServer handles commands, produces events, owns the authoritative state
- **Read side (projections):** Each adapter (player LiveView, DM LiveView, spectator view, future replay) maintains its own projection over the event stream — only the fields it needs, in the shape it needs them
- Projections are updated by consuming events from the bus, not by receiving the full state struct

This separation has practical benefits: the player LiveView need not receive the DM's intervention state; the spectator view can be built from a recorded event history; the DM overlay can maintain extra state (all entity HP, hidden entities) that the player view never sees.

This is a discovery issue: decide the projection model before implementing per-role views or the spectator feature (#92).

**References**
- `docs/polytope-architecture.md` §9 (Temporal dimension: CQRS; Memento for snapshots), §5.2 (event log as unified data/storage/behavior), §8.2 (temporal dimension parallels)
- Issue #111 (event cascade batch — provides the event stream projections consume)
- Issue #92 (spectator role — needs a well-defined projection to work from)
- Issue #101 (DM top-down projection mode — a distinct view that benefits from a separate projection)

**Acceptance criteria**
- [ ] A discovery document or section in `docs/architecture.md` defines what projections exist (player view, DM view, spectator view at minimum) and which event types update each one
- [ ] The boundary is stated: SceneServer does not push its internal state struct to subscribers; adapters subscribe to events and maintain their own projections
- [ ] The migration path from the current full-state-push model is described (can be incremental: project only the fields each view actually uses)
- [ ] Memento/snapshot strategy is noted for reducing replay cost (rebuild projection from last snapshot + events since)
