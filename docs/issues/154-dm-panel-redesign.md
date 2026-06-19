# #154 · DM panel redesign — right panel entity catalog + left panel DM section
**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** ui, gameplay, architecture
**Depends on:** #137 (right panel shell must exist)

Redesign the DM-facing panels to separate catalog from controls, as settled in
brainstorm #22.

**Right panel — DM tab:**

The right panel gains a role-gated "DM" tab (invisible to players). The DM tab has
two sections:

1. **Active entity catalog** (top) — a scrollable list of all scene entities showing:
   - Name
   - Exact HP (e.g. "14 / 28") and condition badges
   - Eye icon button (hide/show entity on map — quick action, no panel open needed)
   - Click row → sets `panel_subject` (opens left panel inspection for that entity)

2. **Entity placement picker** (bottom) — browse catalogue, place entities on the map.
   This is the "Catalogue tab" content from BS-18's right panel design.

Players see only the Events tab (#137). The DM tab does not appear for the player role.

**Left panel — DM section:**

When `is_dm` and `panel_subject` is an entity, a DM section appears below the stat
block in the left inspection panel:
- ±HP spinner (adjust current HP directly)
- Condition picker dropdown (add/remove conditions)
- These controls do not appear for the player role

The Hide toggle moves from left panel DM section → right panel catalog row (eye icon).
Conditions and HP adjustments stay in the left panel (require entity context).

**Acceptance criteria**
- [ ] Right panel has a "DM" tab visible only to DM role
- [ ] DM tab active entity list shows name, exact HP, condition badges, eye icon
- [ ] Eye icon toggles entity visibility on map; fires existing hide/show event
- [ ] Clicking a catalog row sets `panel_subject` to that entity
- [ ] Left panel shows DM section (±HP, condition picker) when `is_dm` and subject is entity
- [ ] DM section not rendered for player role
- [ ] Existing ±HP and condition controls (currently in right panel) removed from old location
- [ ] `mix precommit` passes
