# #101 · DM top-down projection mode (discovery)
**Status:** open
**Opened:** 2026-06-06
**Priority:** low
**Tags:** discovery, rendering, architecture

The isometric perspective makes precise unit placement difficult for the DM on complex or crowded maps. A top-down orthographic view as an optional DM tool solves this without affecting what players see.

Questions to resolve:
- Does the top-down view take over the full DM viewport temporarily, or appear as a minimap-style inset in the DM panel?
- Is it a separate LiveView route or a client-side projection switch (same world state, different render)?
- What is the minimum entity representation in top-down mode: simple colored squares/circles, or full token art scaled to top-down?
- How are tile coordinates displayed (tooltip? grid label overlay?) to aid precise placement?
- Does the SVG coordinate system and tile store need changes to support two projections, or can the tile store be projection-agnostic from the start?

Design constraint: the SVG coordinate system and tile store must be designed (or refactored) to support multiple projections before top-down is implemented — retrofitting is painful.

**Acceptance criteria**
- [ ] All open questions above answered with design decisions
- [ ] Projection-agnostic tile store interface defined (world coordinates are projection-independent; projection is applied at render time)
- [ ] Top-down rendering path sketched (even as pseudocode or a data flow diagram)
- [ ] Decision on DM panel inset vs. full-viewport takeover documented with rationale
- [ ] Any SVG coordinate system changes required to support both projections are captured as follow-up issues
- [ ] Players confirmed to be unaffected by DM projection switch (server state unchanged; client-only or DM-only diff)
