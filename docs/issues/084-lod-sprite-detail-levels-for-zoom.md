# #84 · LOD sprite detail levels for zoom

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** rendering, architecture

Add Level-of-Detail (LOD) to the composable SVG sprite system (#53) so sprites degrade gracefully at low zoom.

At very low zoom, DST-level sprite detail becomes visual noise. Two options:
- **LOD swap:** below a zoom threshold, substitute a simplified silhouette sprite (fewer paths, dominant shape only)
- **Accept noise:** small but coherent sprites still read as distinct characters by silhouette; no extra art needed

LOD is better UX but adds art scope to #53. This issue captures that forward design constraint.

**Design decisions needed:**
- Which option: LOD swap or accept noise?
- If LOD swap: what is the zoom threshold (expressed as a `viewBox` width)? What does the "low-detail" variant of each sprite look like?
- Does LOD affect the composable layer system, or is it a sprite-level switch (replace all layers with a single silhouette)?
- Does LOD interact with the minimap (#81)?

This issue should be resolved together with or after #81 (viewport zoom/pan architecture) since the zoom thresholds are jointly determined.

**Acceptance criteria**
- [ ] Decision documented: LOD swap vs. accept noise
- [ ] If LOD swap: zoom threshold and silhouette art requirements defined
- [ ] Design constraint documented back on #53 (or closed as "accept noise — no art scope change")
- [ ] Implementation issue(s) opened if LOD swap is chosen
