# #135 · Left inspection panel — click-to-inspect map elements

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-19
**Priority:** medium
**Tags:** ui, gameplay, rendering

Implement the left-side detail panel designed in brainstorm #18. The panel shows
stat blocks, tile info, or spell/action cast details depending on what was clicked.
It is display-only — no game state change.

**Depends on:** #134 (`actor_id` rename must land first)

## Design decisions (from brainstorm #18)

**Socket assign:** `panel_subject` (`:entity | :tile | nil`) lives entirely in the
socket. Never enters `GameServer`.

**Click handlers:**
- Entity click (`select_entity`) — updates both `actor_id` (server) and `panel_subject` (socket)
- Tile click (new `inspect_tile` event on ground polygon) — updates `panel_subject` only
- Empty map click (new `deselect` on SVG root) — clears `actor_id`; `panel_subject` persists
- Entity roster click — also drives `panel_subject` (same as map click)
- Move-overlay tile click — triggers move; `panel_subject` retains previous subject

**Role gating:** `inspect_content/2` function takes `(subject, role)` and returns a
data map. Players and DM see different fields for creatures.

**Content per subject type:**

| Subject | Player sees | DM sees |
|---|---|---|
| Hero | Full stat block: name, class, race, level, HP bar, AC, speed, 6 scores, prof bonus, conditions, equipped weapon | Same |
| Creature | Name, creature type (not "monster" — use `monster_type` label), HP bar (no number), temp HP line (if > 0), visible conditions | Full stat block: exact HP, AC, scores |
| Object / decoration | Name, flavour description (from catalogue — issue #132), interaction hint | Same |
| Tile | Texture name, walkable/blocked, movement cost, decoration name if present | Same |

**HP display (players, creatures):** bar only (no number); temp HP as a separate line
when `temp_hp > 0`; no bucket labels.

**DM-only indicator:** a consistent visual marker (eye icon or badge) applied wherever
DM-gated information appears — panel, event log, entity editor. Establish the shared
component here for reuse.

**Panel content types:**
- `:entity` — hero or creature stat block
- `:tile` — tile + decoration info
- `:spell_cast_instance` — catalogue base + "as cast" qualifiers from event resolution context
- `:action_instance` — generalised action with "as resolved" modifier list

**Panel layout:**
- `position: fixed; top: 0; left: 0; bottom: 0; width: ~220px; z-index: 35`
- Scrollable; collapsed until `panel_subject` is set
- Dismissed by ✕ button or `deselect` (empty map click); sticky otherwise

**Acceptance criteria**
- [ ] `panel_subject` socket assign introduced; default `nil`
- [ ] `inspect_tile` event handler implemented; ground polygon has `phx-click="inspect_tile" phx-value-x phx-value-y`
- [ ] `deselect` event on SVG root clears `actor_id` only; `panel_subject` persists
- [ ] Entity roster click sets `panel_subject`
- [ ] `inspect_content/2` implemented with role gating for hero / creature / object / tile
- [ ] DM-only indicator component exists and is applied in the panel
- [ ] HP bar renders without number; temp HP line appears when > 0
- [ ] Creature type label uses `monster_type` (e.g. "Humanoid") — never "monster"
- [ ] Panel dismisses on ✕; persists on move and deselect
- [ ] `mix precommit` exits 0
