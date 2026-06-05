# #4 · Fog of war vs sprites: which comes first

**Status:** closed
**Opened:** 2026-06-04
**Closed:** 2026-06-04
**Priority:** low
**Tags:** discovery

From brainstorming `03-the-proving-grounds.md`. Entities are still colored rectangles with letter initials. Two motivating next steps:

- **Sprites first** — more motivating to play with; unblocks art pipeline and visual identity.
- **Fog of war first** — more architecturally interesting; requires per-player visibility state and selective SVG rendering.

**Decision:** Sprites first, paired with a full visual overhaul to the DST (Don't Starve Together) aesthetic. See `04-dst-aesthetic-sprites.md`. The visual overhaul (isometric rendering + SVG sprites) is tracked in #5 and #6.

**Acceptance criteria**
- [x] Decision recorded here with rationale
- [ ] Chosen feature implemented and playable in the Proving Grounds scenario
