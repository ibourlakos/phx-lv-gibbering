# #160 · UI layer audit — z-index stack and panel layout review

**Status:** open
**Opened:** 2026-06-20
**Priority:** medium
**Tags:** ui, rendering, architecture

The panel layout has grown incrementally across WP-O and WP-P. Several structural
tensions are now visible in the full z-index cross-section and should be resolved
before the panel surface area grows further (left inspection panel #135, appearance
catalogue #132, movement overlay #144).

## Known tensions

**1. z-50 DM controls overlap z-35 right panel**
The DM controls panel (`top:2.5rem; right:0; width:11rem; z-index:50`) physically
overlaps the top portion of the right panel (`width:220px; z-index:35`). The right
panel's tab strip is visible above `top:2.5rem`; below that the z-50 content
covers it. This is an accidental stacking consequence, not a deliberate design. The
DM controls panel should either be absorbed into the right panel's DM tab or given
a non-overlapping position.

**2. Loot panel (z-80) conflicts with right panel**
The container loot panel is `right:16px; top:50%; z-index:80`. It appears over the
right panel when a container is open. This is acceptable short-term but the position
needs review once the right panel has richer DM-tab content.

**3. z-index values are non-contiguous and undocumented**
Current assignments: 0, 20, 30, 35, 50, 80, 100, 110. There is no canonical
reference for what each layer is and why it sits where it does. Future additions
will pick arbitrary values without guidance.

**4. Right panel width vs DM controls width mismatch**
Right panel: 220px. DM controls inner div: 11rem (~176px). Both are pinned to
`right:0`. The DM controls are narrower, leaving a visible gap. When the DM
controls panel is removed or relocated, the right panel should occupy the full
width cleanly.

**5. Left panel has no z-index guard against action bar**
Left panel is z-35 at `left:0`, action bar is z-20 at `bottom:0`. They do not
conflict by z-order, but on small viewports the left panel's lower content may be
hidden behind the action bar (no `padding-bottom`).

## Scope of this issue

This is a **discovery and design** issue. Before implementing fixes, map the intended
final layout:

- Decide where SESSION / INTERVENTIONS / INITIATIVE controls live long-term (inside
  the right panel's DM tab, a dedicated DM toolbar, or kept in the z-50 position but
  repositioned to avoid overlap)
- Define a canonical z-index registry (document it in `docs/architecture/` as a
  reference table)
- Identify any viewport-height overflow risks (small screens, many entities)
- Produce a revised viewport diagram and z-index cross-section as the acceptance
  artifact

Implementation issues for any structural changes derive from this one.

**Acceptance criteria**
- [ ] All current z-index layers documented in a canonical reference (value, name, owner, reason)
- [ ] z-50 DM controls overlap with z-35 right panel resolved — either relocated or a deliberate overlap is explicitly justified
- [ ] Loot panel conflict with right panel assessed and either resolved or deferred with a written rationale
- [ ] Left panel small-viewport overflow (behind action bar) assessed
- [ ] Revised viewport and z-stack diagrams produced confirming the intended layout
- [ ] Any implementation fixes broken into child issues; this issue closes when the diagrams and registry are approved
