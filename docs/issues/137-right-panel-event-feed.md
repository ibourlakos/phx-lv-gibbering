# #137 · Right panel shell + player event feed + active links

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-20
**Priority:** medium
**Tags:** ui, gameplay, architecture

Implement the right-side tabbed panel and its Events tab content, designed in
brainstorm #18. The DM Catalogue tab shell is included here as a placeholder;
its content is populated by issue #132.

**Depends on:** #136 (event visibility taxonomy must land first)

## Design decisions (from brainstorm #18)

**Panel layout:**
- `position: fixed; top: 0; right: 0; bottom: 0; width: ~220px; z-index: 35`
- Replaces the existing bottom-right entity roster + combat log widget
- Tab strip is role-gated: players see Events tab only; DM sees Events + Catalogue

**Events tab:**
- Scrollable narrative feed, newest at bottom
- Players see narrated lines: "Aldric strikes the goblin for 8 slashing damage"
- DM sees mechanical detail layer: roll internals, exact HP, hidden entity events
- Role gating derived from event `visibility` field (issue #136)
- Unread badge on the tab when Events tab is not active
- Revealed events (`:revealed`) render with a DM-disclosure marker

**DM Catalogue tab (shell only):**
- Placeholder component; content to be filled by issue #132
- DM-only — does not render for player role at all (not greyed, absent)

**Active links in feed entries:**
Feed lines are not plain text. Named entities in the narrative are clickable
and set `panel_subject` on the left detail panel.

| Link type | Referent | Panel behaviour |
|---|---|---|
| Entity link ("Aldric", "the goblin") | Current live entity | Opens entity panel (current state); if dead: full stat block + "Fallen" condition marker |
| Tile link | Tile at (x, y) | Opens tile panel (current state; tiles are permanent) |
| Spell/action link ("Fire Bolt") | Event resolution context | Opens `:spell_cast_instance` / `:action_instance` panel: catalogue base + "as cast" qualifiers + modifier list |

**Acceptance criteria**
- [x] Right panel component exists: fixed position, full height, `z-index: 35`
- [x] Tab strip renders Events tab for all roles; Catalogue tab for DM only
- [x] Existing bottom-right entity roster + combat log widget removed
- [x] Events tab renders a scrollable feed with role-appropriate content
- [x] `:public` events appear in both DM and player feed; `:dm_only` in DM only; `:revealed` in both with disclosure marker
- [x] Unread badge appears on Events tab when tab is not active and new events arrive
- [x] Entity links in feed entries set `panel_subject` on the left panel; dead entities show "Fallen" placeholder (full stat block deferred — entity removal snapshots not yet in event schema)
- [x] Tile links in feed entries set `panel_subject` to the tile
- [x] Spell/action links open `:spell_cast_instance` panel with cast-by / target / outcome / roll from event struct; modifier list deferred to Action struct refactor (#152)
- [x] DM Catalogue tab renders as an empty placeholder (content deferred to #132)
- [x] `mix precommit` exits 0

**Implementation notes**
- Right panel: `position:fixed; top:0; right:0; bottom:0; width:220px; z-index:35` — symmetric with left inspection panel. DM controls panel (z-50) sits above it; layout conflict resolved in #154.
- `@active_tab` (`:events | :catalogue`) and `@unread_count` assigns added to mount; `switch_tab`, `inspect_entity`, `inspect_spell_cast` handle_events added.
- `event_parts/1` helpers return `[{:text} | {:entity_link} | {:tile_link} | {:spell_link}]` for structured inline rendering with clickable elements.
- `inspect_content/3` extended: `{:fallen_entity, id}` for dead entities, `{:spell_cast, event}` for spell cast panel.
- DM log section removed from the old z-50 DM controls panel; all events now rendered in the right panel Events tab.
- Entity removal snapshots not yet in event schema → dead entity links show a "Fallen" placeholder; flagged for a future issue.
