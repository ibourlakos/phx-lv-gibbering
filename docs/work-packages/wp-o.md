# WP-O · Inspection Panel & Player Event Feed

**Status:** active
**Source:** brainstorm #18 (all questions resolved)

Two symmetric panels flanking the game grid: a left detail panel for clicking
and inspecting any map element, and a right tabbed panel for the player event
feed and the DM entity catalogue. Backed by an event visibility taxonomy that
gates narrative vs. mechanical content by role.

---

## Issues

| # | Title | Depends on |
|---|---|---|
| [#134](../issues/134-rename-selected-id-to-actor-id.md) | Rename `selected_id` → `actor_id`; introduce `panel_subject` | — |
| [#135](../issues/135-left-inspection-panel.md) | Left inspection panel | #134 |
| [#136](../issues/136-event-visibility-and-dm-reveal.md) | Event visibility taxonomy + LogEntryRevealed / LogEntryHidden structs | — |
| [#137](../issues/137-right-panel-event-feed.md) | Right panel shell + player event feed + active links | #136 |
| [#132](../issues/132-scene-entity-appearance-catalogue-and-seeds.md) | Scene entity appearance catalogue, entity states vocabulary, dev seed coverage | — |
| [#154](../issues/154-dm-panel-redesign.md) | DM panel redesign — right panel entity catalog + left panel DM section | #137 |

---

## Sequencing

```
#134 (actor_id rename)
  └─→ #135 (left panel)
          └─→ [active links need right panel to be open first — coordinate with #137]

#136 (visibility taxonomy)
  └─→ #137 (right panel + feed)
          └─→ #154 (DM panel redesign — right panel DM tab + left panel DM section)

#132 (appearance catalogue + entity states vocabulary)
  ├─→ #135 (flavour descriptions, entity state conditions in panel)
  └─→ #137 (DM Catalogue tab content, appearance variants for dead/condition states)
```

`#134` and `#136` have no dependencies and can start in parallel. `#132` is
independent and can run alongside both chains. `#135` should land before `#137`
so active links in the feed have a left panel to open into. `#154` follows `#137`.

---

## Active Front

```
#137  ──→  #154      (#136 closed — visibility taxonomy shipped)
#132  (parallel, feeds both)
```

---

## Out of scope for this WP

- Inventory modal/lightbox (separate feature — #135 leaves inventory as read-only summary)
- DM Catalogue tab content (#137 delivers the shell; #132 populates it)
- Event schema `modifiers` list and entity removal snapshots (constraint forwarded to a future
  event schema extension issue — dependency of the "as resolved" overlay in #135/#137)
