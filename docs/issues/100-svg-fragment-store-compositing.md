# #100 · SVG fragment store and compositing pipeline (discovery)
**Status:** closed
**Opened:** 2026-06-06
**Closed:** 2026-06-07
**Priority:** medium
**Tags:** discovery, rendering, architecture

Design the architecture for assembling entity visuals from cached SVG fragments rather than re-emitting full SVG on every LiveView patch.

A visible entity is the product of layered appearance components: base body, equipment overlays, status effect tints, selection ring, HP bar, animation state. Each component may be style-specific. Recomputing all of this on every state change is wasteful.

---

## Design Decisions

**Fragment ownership — server-side.**
Elixir composes SVG strings; LiveView diffs handle redundancy. Client-side compositing would require a JS compositing engine and independent state sync with the LiveView model, violating the server-authoritative architecture. No client-side compositing state.

**Cache key structure — deferred to profiling.**
Logical key would be `{sprite_key, style_slug, conditions_fingerprint, hp_state_bucket}` where `conditions_fingerprint = :erlang.phash2(Enum.sort(conditions))` and `hp_state_bucket ∈ {:full, :wounded, :bloodied, :critical}`. However, LiveView's own diffing is the primary deduplication mechanism: if entity state doesn't change, the server emits the same assigns, and LiveView pushes no patch. An explicit ETS cache (keyed as above) is deferred until profiling shows it is needed. See #104.

**SVG `<defs>` / `<symbol>` strategy — direct emission now, `<symbol>` for repeated static geometry.**
For the current scale (small maps, few entities), direct SVG emission per entity is simpler and correct. `<symbol>` + `<use href>` is beneficial when the same static geometry appears many times (e.g., 20 identical goblins). Define `<symbol>` elements for static body shapes when profiling justifies it; overlays (HP bars, selection rings, condition tints) are always emitted per-entity because they carry per-instance state.

**Cache invalidation — implicit via LiveView diffing.**
Style switch: `appearances_for_style/1` is called at mount; a style switch requires a remount (or an explicit `assign/3` update). Entity state change: LiveView re-renders only assigns that changed. No explicit invalidation logic needed until a cache is added.

**Layer ordering — declarative, compositing is a pure function.**
Layer list: `[:body, :selection_ring, :hp_bar]` (bottom to top in draw order).
`SpriteCompositor.compose/3` is a pure function of `(entity, appearances, opts)` — no DB access, no side effects, fully unit-testable without a browser.

**Geometry / anchor points — stored in appearance data.**
Each sprite's bounding box origin is style-specific. Anchor offsets `anchor_x` and `anchor_y` live in `appearances[{"entity", sprite_key}]` as integer fields, defaulting to `{0, 0}` (top-left of sprite box). The compositor positions the fragment; the caller wraps it in `<g transform="translate(sx, sy)">` for tile placement.

**`<use>` vs. direct emission — direct emission is correct for now.**
`<use>` reduces DOM node count for repeated identical sprites but adds indirection for per-instance state. At current map scales (≤20 entities on screen), the savings are negligible. The break-even is roughly when 10+ entities share identical appearance and conditions simultaneously. Document and revisit when the map editor (WP-H #89) ships dense monster packs.

---

**Acceptance criteria**
- [x] All open questions above answered with design decisions
- [x] Fragment cache key structure defined
- [x] Compositing pipeline described as a data structure + pure function pair (testable without browser)
- [x] Geometry / anchor point storage strategy defined
- [x] Proof-of-concept shows a two-layer composite entity rendered correctly (`SpriteCompositor.compose/3`, 14 unit tests, all green)
- [x] Performance trade-off between `<use>` compositing and direct emission documented
- [x] Follow-up implementation issue created: #104
