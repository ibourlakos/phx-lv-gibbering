# #143 · Campaign outcome screen

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-19
**Priority:** high
**Tags:** ui, gameplay

## Context

Once #142 ships `:victory`/`:defeat` phase transitions, all connected LiveViews need
to render an outcome screen that communicates the result to players and provides a
clear next step.

## What needs to happen

1. `GameLive` handles `%Events.PhaseChanged{new_phase: :victory | :defeat}` and
   transitions its local `scene_phase` assign accordingly.
2. Render an overlay (full-viewport, above the map) when `scene_phase` is `:victory`
   or `:defeat`:
   - Victory: "Victory!" heading + brief static flavour line.
   - Defeat: "Defeat…" heading + brief static flavour line.
   - Both show the turn count and any kills (derivable from current event log).
3. DM sees an additional "Return to Lobby" button that fires a `transition_phase`
   command (`:victory/:defeat → :lobby`). This button is hidden for players.
4. Players see a static screen — no action, just result. They remain on the page
   until the DM resets.

## Out of scope

- Configurable flavour text per campaign (hardcode static strings for now).
- XP/loot summary on the screen (loot is handled separately by the inventory system).

**Acceptance criteria**
- [x] Victory overlay renders for all connected LiveViews when phase is `:victory`
- [x] Defeat overlay renders for all connected LiveViews when phase is `:defeat`
- [x] Overlay shows turn count; kill count is a nice-to-have
- [x] DM sees "Return to Lobby" button; players do not
- [x] "Return to Lobby" sends `transition_phase(:lobby)` and all sockets return to game/lobby state
- [x] Player inputs remain blocked while overlay is shown (no map interaction)
- [x] `mix precommit` passes

**Implementation notes:**
- Round count tracked in LiveView assigns from `%TurnAdvanced{round_number: n}` events.
  Players who connect after combat starts see rounds since they joined.
- `dm_return_to_lobby` event calls `SceneServer.force_transition_phase(game_id, :lobby)`.
- Overlay uses `z-index:100` (no `pointer-events:none`) — naturally blocks all map interaction.
- Kill count omitted (nice-to-have, no kill tracking in current State).
