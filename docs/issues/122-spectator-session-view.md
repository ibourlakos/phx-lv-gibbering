# #122 · Spectator session view: shared GameLive mount, full-map default, PC-perspective toggle
**Status:** open
**Opened:** 2026-06-12
**Priority:** low
**Tags:** architecture, ui, gameplay

Wire the spectator experience into the existing GameLive: detect spectator role, render full-map view by default, hide action controls, and provide a client-side toggle to a specific PC's fog perspective.

Derived from #92 (spectator role discovery). Depends on #121 (spectator membership model).

## Scope

**Mount detection**
- On `GameLive.mount/3`, read `membership_role` from the session/assigns
- Gate action controls (ability bar, end-turn button, move confirmation, etc.) behind `role != :spectator`

**Visibility scope**
- Spectators receive the full game state projection from `%EventBatch{}` broadcasts (same PubSub subscription as players: `"game:#{campaign_id}"` and `"notifications:#{campaign_id}"`)
- No FOW filter applied to the spectator's scene render by default (full map visible)
- Client-side toggle: `spectator_view: :full | {:pc, entity_id}` in socket assigns
  - `:full` — render all tiles, no FOW mask
  - `{:pc, entity_id}` — apply FOW mask using only that entity's visibility radius (same logic as the chosen PC's player view)
- Toggle UI: a small PC selector in the spectator HUD; defaults to `:full`

**Spectator count display**
- All connected users (players + DM) see an aggregate spectator count in the session HUD
- Each player additionally sees the names of spectators they personally invited (`invited_by_user_id == current_user.id`)
- DM sees the full spectator list with names and who invited each, in the DM panel

**Notes**
- Spectators are PubSub-only: they never call GameServer command handlers. The LiveView must not expose any command-dispatching event handlers to spectator sockets.
- A dedicated spectator LiveView module is a named future consideration if the spectator UX grows to require replay, multi-panel, or picture-in-picture views.

**Acceptance criteria**
- [ ] `GameLive` detects `membership_role: :spectator` and hides all action controls
- [ ] Spectator receives full game state via PubSub; no GameServer client registration occurs
- [ ] Default render: full map, no FOW mask
- [ ] PC-perspective toggle updates `spectator_view` in socket assigns and re-renders FOW accordingly
- [ ] Aggregate spectator count visible in session HUD to all users
- [ ] Player sees names of their own invitees in the spectator list
- [ ] DM panel shows full spectator list with inviter attribution
- [ ] No command-dispatching event handlers reachable from a spectator socket
- [ ] LiveView tests cover: spectator mount, full-map render, PC-perspective toggle, count display
