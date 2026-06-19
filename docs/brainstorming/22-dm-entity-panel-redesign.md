# Brainstorm #22 — DM entity panel redesign

**Status:** open

## Context

The current right-side DM entity panel combines two concerns:
- A **catalog** (list of entities in the scene with HP indicators)
- **Adjustment controls** (±HP spinners, condition dropdowns, Hide toggle)

Mixing these makes the panel dense and clutters the at-a-glance view.
The suggestion is to keep the right panel as a pure catalog and move all
DM-only adjustment controls into a new DM tab on the left inspection panel
(the same panel that already shows stat blocks when an entity is clicked).

## Open questions

- What does the **right catalog** show per entity in the minimal view?
  - Name
  - HP bar (no number for players; exact for DM)
  - Visibility indicator (hidden/visible badge)?
  - Click-to-inspect shortcut (same as clicking on map)?

- The left panel already has an "Inspect" header. The DM tab would add
  adjustments (±HP, conditions, Hide) when the panel subject is an entity.
  Should this be:
  - A **tab strip** inside the panel (Inspect | DM Controls)?
  - A **section** that appears below stat info only when `is_dm`?
  - Or an entirely separate DM overlay triggered by a separate action?

- Where does the **Hide** toggle live? Right panel (catalog row) or left
  panel DM tab? Hiding an entity from the map is a quick DM action that
  might benefit from being in the catalog (no click-to-open required).

- How does the **condition dropdown** interact with the left panel? Currently
  it lives in the right panel. Moving it to the left panel means the DM must
  click an entity first to set a condition — acceptable UX?

- Does the redesign affect **player-facing** right panel? Eventually the right
  panel will show the player event feed (issue #137). The DM catalog would
  coexist with or replace the feed for the DM role — needs a clear slot model.

## Cross-references

- Related: issue #137 (right panel shell + player event feed)
- Related: issue #135 (left inspection panel — already built)
- The DM tab would be an extension of the #135 panel, not a new panel
