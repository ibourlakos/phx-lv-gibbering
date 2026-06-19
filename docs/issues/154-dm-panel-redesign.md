# #154 · DM panel redesign — right panel entity catalog + DM intervention panel
**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** ui, gameplay, architecture
**Depends on:** #137 (right panel shell must exist)

Redesign the DM-facing panels to separate passive observation (catalog) from active
intervention. DM interventions are inherently exceptional — the UX should reinforce
that the DM is stepping outside the normal game flow to adjust something. This means
intervention controls live in a **dedicated, explicitly-triggered panel**, not a section
that passively appears whenever an entity is selected.

**Right panel — DM tab (passive, always visible to DM):**

The right panel gains a role-gated "DM" tab (invisible to players). The DM tab has
two sections:

1. **Active entity catalog** (top) — a scrollable list of all scene entities showing:
   - Name
   - Exact HP (e.g. "14 / 28") and condition badges
   - Eye icon button (hide/show entity on map — the one DM action lightweight enough to be inline)
   - Click row → sets `panel_subject` (opens left panel inspection for that entity)

2. **Entity placement picker** (bottom) — browse catalogue, place entities on the map.

Players see only the Events tab (#137). The DM tab does not appear for the player role.

**DM intervention panel (explicit, entity-scoped):**

HP adjustments and condition changes are exceptional acts — the DM is overriding game
state. They live in a separate panel that the DM must explicitly open:

- Triggered by an "Intervene" button or icon in the entity catalog row (or the left
  inspection panel header when the DM has an entity selected)
- Appears as a distinct visual surface (slide-in panel, modal, or fixed overlay) —
  separate from both the inspection panel and the catalog
- Contents: ±HP spinner, condition picker, any future DM override controls
- Dismissed explicitly (close button or clicking away)

The visual separation makes clear: "I am about to do something exceptional to this entity."

**Acceptance criteria**
- [ ] Right panel has a "DM" tab visible only to DM role
- [ ] DM tab active entity list shows name, exact HP, condition badges, eye icon
- [ ] Eye icon toggles entity visibility; fires existing hide/show event
- [ ] Clicking a catalog row sets `panel_subject`
- [ ] An "Intervene" affordance (button/icon) on catalog rows and/or left panel header opens the DM intervention panel
- [ ] DM intervention panel is a distinct visual area (not inline in left panel)
- [ ] Intervention panel contains ±HP spinner and condition picker
- [ ] Intervention panel is not rendered for the player role
- [ ] Existing ±HP and condition controls removed from old right panel location
- [ ] `mix precommit` passes
