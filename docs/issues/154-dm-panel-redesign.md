# #154 · DM panel redesign — right panel entity catalog + DM intervention panel
**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-20
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
- [x] Right panel has a "DM" tab visible only to DM role
- [x] DM tab active entity list shows name, exact HP, condition badges, eye icon
- [x] Eye icon toggles entity visibility; fires existing hide/show event
- [x] Clicking a catalog row sets `panel_subject`
- [x] An "Intervene" affordance (button/icon) on catalog rows and/or left panel header opens the DM intervention panel
- [x] DM intervention panel is a distinct visual area (not inline in left panel)
- [x] Intervention panel contains ±HP spinner and condition picker
- [x] Intervention panel is not rendered for the player role
- [x] Existing ±HP and condition controls removed from old right panel location
- [x] `mix precommit` passes

**Implementation notes**
- Old z-50 DM panel ENTITIES section (inline ±HP/condition/hide per entity) removed; replaced by DM tab entity catalog in the right panel.
- DM tab renders in `@active_tab == :dm` guard (DM only); player sees only Events tab.
- Intervention panel: `@dm_intervene_entity_id` assign (nil = closed); `open_dm_intervene` / `close_dm_intervene` handle_events; reuses existing `dm_adjust_hp` and `dm_apply_condition` form submission.
- Entity placement picker: placeholder section at bottom of DM tab — content deferred to #132.
- `switch_tab` handler replaced `String.to_existing_atom` with explicit case for safety now that `:dm` is a valid tab value.
