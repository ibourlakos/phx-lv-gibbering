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

## Decisions

| Question | Decision |
|---|---|
| Right catalog minimal view? | Name, exact HP (DM only), hidden/visible badge, click-to-inspect shortcut (sets `panel_subject`). |
| DM controls location? | Separate explicit intervention panel — not a passive section. DM must trigger it deliberately (Intervene button). The visual separation reinforces that HP/condition changes are exceptional acts, not routine inspection. |
| Hide toggle location? | Right panel catalog row — eye icon button per row. Quick action without opening inspection panel. |
| Condition dropdown location? | Left panel DM section. DM clicks entity → left panel shows stat block + DM section with condition picker. |
| Player-facing vs. DM right panel? | Right panel is role-gated. DM sees a "DM" tab (two sections: active scene entity catalog + entity placement picker). Players see Events tab only (from #137). |

## Issues Opened

| Issue | Title | Status |
|---|---|---|
| [#154](../issues/154-dm-panel-redesign.md) | DM panel redesign — right panel entity catalog + left panel DM section | open |

This brainstorm will be deleted when #154 is closed.
