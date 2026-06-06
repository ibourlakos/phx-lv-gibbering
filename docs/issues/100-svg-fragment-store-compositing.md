# #100 · SVG fragment store and compositing pipeline (discovery)
**Status:** open
**Opened:** 2026-06-06
**Priority:** medium
**Tags:** discovery, rendering, architecture

Design the architecture for assembling entity visuals from cached SVG fragments rather than re-emitting full SVG on every LiveView patch.

A visible entity is the product of layered appearance components: base body, equipment overlays, status effect tints, selection ring, HP bar, animation state. Each component may be style-specific. Recomputing all of this on every state change is wasteful.

Questions to resolve:
- **Fragment ownership**: server-side (Elixir produces SVG strings) vs. client-side (JS hook assembles from a data payload) — which layer owns compositing?
- **Cache key granularity**: `(content_id, style_id, variant)` where variant captures animation frame, equipment hash, condition set — how coarse/fine?
- **SVG `<defs>` / `<symbol>` strategy**: fragments as `<symbol>` elements referenced by `<use href>` vs. direct SVG emission — when does `<use>`-based compositing outperform direct emission?
- **Cache invalidation**: style switch invalidates full style cache; entity state change invalidates only that entity's variant key — confirm this is tractable
- **Layer ordering**: declarative layer list (body → equipment → conditions → selection ring) as a data structure; compositing is a pure function — verify this is testable without a browser
- **Geometry**: anchor points per appearance (style-dependent bounding boxes, anchor at bottom-center vs. tile-center) — how are these stored?

Output: a design document with concrete decisions for each question, and a minimal proof-of-concept (can be a unit test or a standalone Elixir script) demonstrating the compositing pipeline for a two-layer entity.

**Acceptance criteria**
- [ ] All open questions above answered with design decisions
- [ ] Fragment cache key structure defined
- [ ] Compositing pipeline described as a data structure + pure function pair (testable without browser)
- [ ] Geometry / anchor point storage strategy defined
- [ ] Proof-of-concept shows a two-layer composite entity rendered correctly
- [ ] Performance trade-off between `<use>` compositing and direct emission documented (even if just a reasoned estimate)
- [ ] Follow-up implementation issue created (or this issue upgraded)
