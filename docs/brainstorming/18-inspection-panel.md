# #18 · Inspection Panel — Click-to-Inspect Map Elements

## Context

The game scene has no way to inspect what's on the map. Clicking an entity selects it for
action (move, attack, spell) but shows no details. Tiles, decorations, and objects are not
clickable at all. A persistent inspection panel on the left side — showing stats for heroes,
abbreviated info for monsters, flavour for objects and decorations, and terrain info for tiles
— would make the scene legible and bring it closer to what a game like Baldur's Gate 3 offers
at a glance.

This brainstorm maps the design space before any implementation is committed to.

---

## Current state

- `state.selected_id` (in `GameServer` / `Engine.State`) — entity ID only; drives combat targeting
- Ground tile polygons have no `phx-click`; move-overlay polygons sit on top and already consume pointer events on walkable tiles
- Bottom-right panel shows a bare HP list and a combat log — it is not an inspector
- Left side of the viewport is completely free

---

## Topic areas

### 1. Selection model — one concern or two?

`selected_id` currently carries two meanings:
- "this entity is ready for a combat action" (attacker / caster)
- loosely "this is the active hero you're controlling"

An inspection panel adds a third use case: "I clicked this thing and want to read about it."

**Options:**

A. **Reuse `selected_id` + derive panel content from it** — the simplest path; inspection just renders what's already selected. Limitation: no way to inspect a tile or decoration since those have no ID.

B. **Add a socket-level `inspected` assign** (`:entity | :tile | :decoration | nil`) separate from `selected_id` — inspection is display-only and never enters `GameServer` state; clicking anything sets `inspected`, combat actions still use `selected_id`. Clicking a second entity updates both.

C. **Split `selected_id` into two**: `action_target_id` (combat) and `selected_id` (inspection, panel-driven). Cleanest semantically, but touching all existing combat logic is a large blast radius.

**Decision: B.** It layers cleanly on top of the existing model with no engine changes. The socket holds ephemeral UI state; the server holds game state. That boundary already exists.

**Naming (resolved):**
- `selected_id` (game server) → **`actor_id`** — the entity currently taking or about to take a combat action
- `inspected` (socket assign) → **`panel_subject`** (type: `:entity | :tile | nil`) — display-only, never enters game server state
- Inventory is a separate concern with its own modal/lightbox, independent of the inspection panel

---

### 2. What is inspectable?

| Element | Click handler | Panel content |
|---|---|---|
| Hero | existing `select_entity` | Name, class, race, level · HP bar · AC · Speed · 6 ability scores + mods · Prof bonus · Conditions · Equipped weapon · Inventory summary |
| Monster | existing `select_entity` | Name, type · HP bar (player sees rough: "Bloodied / Healthy") · AC (DM only: exact; player: none) · Conditions |
| Object (static_decor) | new `inspect_entity` or reuse `select_entity` | Name · Flavour description · "Cannot be interacted with" or interaction hint |
| Object (loot_source) | reuse `select_entity` (already opens container panel) | Same as loot flow — container panel already handles this |
| Tile (no entity) | new `inspect_tile` on ground polygon | Texture name · Walkable / Blocked · Movement cost · Decoration name if present |
| Decoration (on tile) | same `inspect_tile` (tile knows its decoration) | Decoration type · Flavour line |

**Resolved (Q1):** Yes — roster clicks drive the inspection panel, same behaviour as BG3.

---

### 3. Tile click coordination with move overlay

Ground tile polygons are layer 1. Valid-move overlay polygons are layer 4 (rendered after entities so they're always on top). When a move overlay exists on a tile, it already consumes the pointer event — the tile polygon underneath is never reached.

This is actually fine for inspection:
- If a tile has a move overlay, clicking it triggers "move" — the entity moves there, which is the expected action. Inspection of that tile is less important in that moment.
- If a tile has no overlay (not a valid move, or no entity selected), we can add `phx-click="inspect_tile" phx-value-x phx-value-y` to the ground polygon.
- Entity polygons sit above ground tiles, so entity clicks still take precedence.

**Resolved (Q3):** Retain the previous `panel_subject` — moving does not imply loss of interest in what was being inspected.

---

### 4. Information visibility — role gating

The same entity looks different to a player vs. the DM.

**Hero** (any role sees full stats — it's their own character or an ally):
- All 6 scores, HP, AC, conditions, inventory.

**Non-hero creature** (information should be gated):
- **DM**: Full stat block — exact HP, AC, ability scores.
- **Player**: Name + HP bar (no numbers) + temp HP line when > 0 + visible conditions only. No AC, no scores. The entity schema already carries `hp`, `max_hp`, and `temp_hp` — all three are available. "Shield points" are not a RAW 5e mechanic (Shield and Shield of Faith spells grant AC bonuses, not a separate HP pool); temp HP is the only analogous concept.

**Object / Tile**: Same for all roles — no sensitive info.

This gating needs a helper in the template, or a separate `inspect_content/2` function that takes `(subject, role)` and returns a data map.

**UI terminology note:** The word "monster" is an internal engine/data concept (`entity.type: "monster"` in the DB). It must not surface to players. In the panel, display the creature's `monster_type` from the catalogue (e.g. "Humanoid", "Beast", "Undead", "Fiend") as the type label. "Monster" may appear in DM-only tooling (entity editor, catalogue management) where it is the correct technical term.

**Resolved (Q5):** Flavour description lives in the entity catalogue (issue #132), not on entity instances. Instances inherit the catalogue description; a per-instance override is optional. `object_subtype` is also promoted from a `stats` map key to a validated catalogue field — see issue #132 for acceptance criteria.

**Resolved (Q7):** DM sees the full stat block with a consistent visual "DM-only" indicator (e.g. eye icon or subtle badge). This indicator applies consistently across the entire UI wherever DM-gated information appears — panel, event log, entity editor.

---

### 8. Player event feed

A scrolling event feed visible in the player's viewport — separate from the DM's mechanical combat log.

**Distinction from the existing log:**
- DM log: raw mechanical outcomes — "Goblin rolls 14 vs AC 15 — miss", exact HP values, hidden entity events.
- Player feed: narrated events — "Aldric strikes the goblin for 8 slashing damage", "You find a shortsword in the chest", "A dart flies from the wall — 3 piercing damage."

**Role gating applies:**
- Players do not see dice roll internals, exact monster HP, or events involving hidden entities.
- The DM sees everything plus the mechanical detail layer.

**Structural dependency:** the feed is the display layer for the scene event log. Every `Action` resolution emits events (`:damage_dealt`, `:spell_cast`, `:trap_triggered`, `:item_looted`, etc.) that must carry enough data to render both a mechanical DM line and a narrative player line from the same event struct. This is a constraint on the event schema (see brainstorm #19 — event chaining), not just the UI.

**Positioning:** the left side is reserved for the detail panel. Turn strip is bottom-center. Entity roster is bottom-right. The event feed is a candidate for bottom-left or a collapsible overlay. Needs resolving against the full viewport layout (issue #102).

#### Event visibility taxonomy

Every scene event carries a `visibility` field. Three values:

| Value | Meaning |
|---|---|
| `:public` | Shown in both DM log and player feed |
| `:dm_only` | Shown in DM log only; players see nothing |
| `:revealed` | Was `:dm_only`; DM explicitly pushed it to the player feed |

Default visibility by event category:

| Event | Default | Rationale |
|---|---|---|
| Hero attacks (roll + outcome) | `:public` | Player actions are visible fiction |
| Hero casts spell (name + outcome) | `:public` | Same |
| Hero moves | `:public` | Visible to all |
| Hero takes damage (amount) | `:public` | It's happening to the player |
| Hero condition applied/removed | `:public` | Visible effect |
| Creature attack roll (exact d20 value) | `:dm_only` | Internal mechanics of DM-controlled entity |
| Creature attack outcome (hit/miss) | `:public` | Player sees the result, not the roll |
| Creature damage dealt (amount) | `:public` | Player feels the hit |
| Creature saving throw (exact roll) | `:dm_only` | DM's dice |
| Creature saving throw outcome (pass/fail) | `:public` | Player sees the spell succeed or fizzle |
| Creature HP change (exact value) | `:dm_only` | Players see HP bucket changes, not numbers |
| Creature condition applied/removed | `:public` | Visible fiction ("the goblin looks dazed") |
| Creature death / unconscious | `:public` | Visible |
| Hidden entity any event | `:dm_only` | Entity isn't perceived by players at all |
| DM override (HP set, condition forced) | `:dm_only` | DM god-mode action |
| Trap triggered (visible effect) | `:public` | Players see the dart fly |
| Trap triggered (hidden trap, not yet sprung) | `:dm_only` | DM awareness only |
| Loot found | `:public` | Player opened the chest |
| Initiative roll (creatures) | `:dm_only` | DM's rolls |
| Initiative roll (heroes) | `:public` | Players rolled their own dice |
| Turn start / turn end | `:public` | Turn structure is shared |

#### DM reveal mechanism

The DM can promote any `:dm_only` event to `:revealed`, pushing it to the player feed. This covers:
- "I rolled a 20 — showing you that crit was real"
- Narrating a monster's saving throw result as drama ("the goblin barely resists your spell — rolled a 10")
- Confirming a contested roll outcome publicly

**UX:** In the DM event log, each `:dm_only` line has a "reveal" affordance (an eye icon or similar). Clicking it updates the event's visibility to `:revealed` and broadcasts the update — the event appears in connected player feeds in real time.

**Reveal rendering in the player feed:** revealed events should carry a visual marker (e.g. a small DM icon) so players know this was DM-disclosed, not a mechanical default.

**Implementation note:** Reveal and hide are modeled as their own events in the Published Language (issue #119) — the event log stays append-only throughout:

```
%Events.LogEntryRevealed{ original_event_id: event_id, revealed_at: DateTime.t() }
%Events.LogEntryHidden{   original_event_id: event_id, hidden_at:   DateTime.t() }
```

The player feed projection folds the log in order: `LogEntryRevealed` makes the referenced event visible; `LogEntryHidden` removes it; a subsequent `LogEntryRevealed` restores it. The DM can toggle freely. No mutation of past events — visibility is a derived property of the projection, not a stored attribute on the original event struct.

`%Events.LogEntryHidden{}` can only retract a previously revealed event — it does not suppress events that are `:public` by default. Hiding a naturally public event (e.g. suppressing a hero's roll retroactively) is out of scope.

#### Active links in event feed entries

Event feed lines are not plain text — named entities in the narrative are clickable and open the detail panel.

Example: *"Aldric casts Fire Bolt on the dead tree"* — three links, three referent types:

**Entity links** ("Aldric", "the goblin") → always current live state. If the entity is dead or gone, the panel shows a tombstone: last known stats + a "Deceased" / "No longer present" marker. Players generally want current state, not a historical snapshot.

**Tile links** → always safe; tiles are permanent. Even if the tree entity is gone, the tile remains. Link shows current tile state (texture, decoration, movement cost).

**Spell/action links** ("Fire Bolt") → the referent problem. The catalogue entry shows the base spell definition, but the cast may have been modified: upcast to a higher slot level, altered by metamagic (Empowered Spell, Heightened Spell), or boosted by a passive rule modifier. The base definition alone is accurate but incomplete.

Resolution: spell links open the panel in a **cast instance mode** — the catalogue definition as base, with "as cast" qualifiers overlaid from the event's stored resolution context:

```
Fire Bolt
Evocation cantrip · Ranged spell attack

As cast: level 3 slot · Heightened Spell (save at disadvantage)
Damage rolled: 3d10+4 = 19 fire
```

This is a new content type for the detail panel: `:spell_cast_instance` alongside the existing `:spell_definition`, `:entity`, and `:tile` types. No new data fetch required — the event already carries its resolution context.

**If the catalogue definition changes mid-session** (DM edits a spell): the event log stays accurate because it stores resolution context, not a pointer to the catalogue. The link shows the *current* catalogue definition plus the *actual* resolution qualifiers — no gap.

**Resolution context and modifiers (Q10):** The overlay generalises beyond spells — all action types carry a `modifiers` list in their resolution context, covering passive features, conditions, and environmental effects (e.g. "Muddy terrain at (3,4) halved movement"). The panel renders this list as "as resolved" qualifiers. This is a constraint on the event schema (issue #119); the panel requires no additional design.

---

### 5. Panel layout

**Resolved (Q8): Two-panel layout — left detail, right tabbed.**

```
┌──────────┬──────────────────────┬──────────┐
│          │                      │          │
│  Detail  │      Game Grid       │ [Events] │
│  (left)  │                      │[Catalogue│
│          │                      │  DM only]│
└──────────┴──────────────────────┴──────────┘
                 [Turn Strip]
```

**Left panel** — Detail / Inspection (`panel_subject`):
- Fixed width `~220px`, `position:fixed; top:0; left:0; bottom:0; z-index:35`
- Scrollable; dismissed by ✕ or clicking empty map space
- Collapsed until something is inspected

**Right panel** — Tabbed:
- Fixed width `~220px`, `position:fixed; top:0; right:0; bottom:0; z-index:35`
- **Events tab** (all roles): scrollable narrative feed, newest at bottom; badge shows unread count when tab is not active
- **Catalogue tab** (DM only): scene entity picker — browse catalogue, place entities on the map
- Tab strip is role-gated: players see only the Events tab; the Catalogue tab does not appear at all (not greyed out, not present)

The existing bottom-right entity roster (bare HP list) is replaced by this panel. The turn strip remains bottom-center and is unaffected.

---

### 6. Clearing / persistence

Options:
- **Sticky**: Panel stays open showing the last inspected subject until explicitly dismissed. Good for referencing stats while acting.
- **Auto-clear on action**: Executing a move, attack, or spell clears the panel. Clean, less noise.
- **Auto-clear on turn end**: Panel persists within a turn, clears when turn advances.

BG3 uses sticky. Recommendation: sticky, dismissable by clicking empty map space (which can also clear `actor_id`) or the ✕ button.

Clicking empty map space currently does nothing — we can add `phx-click="deselect"` to the SVG root (pointer events bubble up if no child consumes them).

---

### 7. Socket vs. server state

The `panel_subject` assign should live **entirely in the socket** (`assign(socket, panel_subject: ...)`). It is display-only, per-client, and has no gameplay effect. No `GameServer` changes needed.

`select_entity` continues to update both `actor_id` (server state, game effect) and `panel_subject` (socket, display). `inspect_tile` updates only `panel_subject`.

---

## Open questions

- [x] Q1: Does clicking the entity roster (bottom-right) also drive the inspection panel? → **Yes.**
- [x] Q2: When a player clicks a monster, what HP granularity do they see? → **HP bar (no number); temp HP as a separate line when > 0. No buckets, no exact numbers.**
- [x] Q3: Does clicking a move-overlay tile clear the panel or retain the previous subject? → **Retain.**
- [x] Q4: Does "deselect" (click empty map) clear both `actor_id` and `panel_subject`, or only `actor_id`? → **`actor_id` only; `panel_subject` persists.**
- [x] Q5: Flavour description for `static_decor` — stored or derived? → **Stored on the catalogue entry (issue #132); instances inherit. `object_subtype` promoted from `stats` map to validated catalogue field.**
- [x] Q6: Should the inventory summary be read-only or interactive? → **Read-only for v1; inventory has its own modal/lightbox.**
- [x] Q7: What does the DM panel show for a hidden entity? → **Full stat block with a consistent DM-only visual indicator (eye icon / badge), applied uniformly across the UI.**
- [x] Q8: Where does the player event feed sit in the viewport layout? → **Right panel, tabbed: Events (all roles) + Catalogue (DM only). Tab strip is role-gated — players see only their tabs.**
- [x] Q9: For tombstone entity links (dead/gone entity), how much of the last-known stat block is shown? → **Full panel, same role-gating as when alive. Death is just a condition (`:dead`, `:destroyed`) — the panel renders current entity state with the condition surfaced as a "Fallen" / "Destroyed" label. No special tombstone mode. Appearance change at 0 HP is handled by the appearance system (issue #132). For entities removed from the scene entirely (fled, teleported), the death/removal event must carry a state snapshot; this is a constraint on the event schema (issue #119).**
- [x] Q10: Should passive rule modifiers that applied to a cast be recorded in the event's resolution context? → **Yes — generalised beyond spells: all action types carry a `modifiers` list in their resolution context (environmental, passive feature, condition-driven). The "as resolved" overlay in the panel renders this list. Constraint forwarded to issue #119 (event schema). Panel rendering requires no additional design here.**
