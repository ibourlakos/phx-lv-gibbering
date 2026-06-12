# #85 · Content creation tools — design and scope

**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** Path [F] candidate — spans admin shell, player shell, five editor component types, UGC moderation, and preview rendering. Too broad for in-issue settlement. Promote to a brainstorm when admin app foundation (#64–#69 closed) and core content pipeline are stable.
**Priority:** low
**Tags:** discovery, architecture, ui, admin

Design the content creation toolset: what components are shared, and how the admin-panel shell and the player-facing game-app shell diverge.

Brainstorm #09 (admin web app) deferred this as a separate topic. The high-level shape is already known:

**Shared surface** (same schemas, validation logic, core editor components):
- Item editor (weapon, armour, consumable properties)
- Race editor (traits, ability score bonuses, speed, size)
- Class editor (hit die, features per level, spell progression)
- Map module editor (tiles, room layouts, decoration placement)
- Preview rendering (render the content using the live SVG pipeline)

**Divergent shell:**
- **Admin panel** — platform-scoped, no ownership, bulk operations, immediate publish or direct DB insert; accessed by support editors
- **Game app** — user-owned, visibility controls (private / campaign / public), submission and review workflow; accessed by players in a content creator mode within their account area

See brainstorm #09 decisions for the UGC moderation model (`content_trust` flag, status lifecycle, #70 for UGC schema).

**Open questions to settle:**
- Which editor component comes first — item, race, class, or map?
- Is preview rendering in the editor live (real-time SVG update as fields change) or on-demand?
- How does the admin shell differ structurally from the player shell — separate LiveView layouts, or a shared editor embedded in both?
- What is the minimal viable editor for MVP (text fields only, no drag-and-drop)?
- Does map module editing belong in this brainstorm or in a separate rendering/tools brainstorm?

**Acceptance criteria**
- [ ] All open questions have a documented decision
- [ ] Shared editor component list and priority order are defined
- [ ] Admin shell vs. player shell structural differences are documented
- [ ] Implementation issue(s) for the first editor component are opened
