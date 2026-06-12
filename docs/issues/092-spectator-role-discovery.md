# #92 · Spectator role — campaign membership and session view (discovery)
**Status:** closed
**Opened:** 2026-06-06
**Closed:** 2026-06-12
**Priority:** low
**Tags:** discovery, architecture, gameplay

Spectators can observe a live session but have no in-game actions.

## Decisions

| Q | Decision |
|---|---|
| Membership model | `membership_role: :spectator` on campaign membership record. Any campaign member (player or DM) can send a spectator invite. Player invites (granting `membership_role: :player`) remain DM-only. Each membership record tracks `invited_by_user_id` so players can see their own invitees. |
| LiveView strategy | Shared GameLive mount. Spectator role is detected from `socket.assigns.membership_role`; action controls are hidden. No separate LiveView module for initial implementation. A dedicated spectator client (replay, multi-panel, picture-in-picture) is a named future consideration if the spectator UX grows complex enough to warrant it. |
| Visibility scope | Full map visibility by default (DM-equivalent, no FOW filter). Spectator can client-side toggle to a specific PC's fog perspective — this is purely a filter on data already held in socket assigns (`spectator_view: :full \| {:pc, entity_id}`). No server round-trip required. |
| Spectator visibility to others | All players see an aggregate spectator count. Each player sees the names of spectators they personally invited. DM sees the full spectator list with who invited each. |
| Spectator → player promotion | DM sends a player invite to an existing spectator. The spectator disconnects from their spectator session, accepts the invite, and reconnects as a full player through the normal join flow. No in-place promotion; no state migration. From the server's perspective it is a new player joining. |
| Server process | Spectators are PubSub subscribers only — they receive `%EventBatch{}` broadcasts on `"game:#{campaign_id}"` but are never registered as GameServer clients and never send commands. The spectator LiveView is a read-only projection. |

## Future Considerations

These are noted for future exploration and intentionally not tracked as issues:
- Open spectating: a campaign or per-session DM toggle allowing anyone with the link to spectate without an explicit invite.
- PC assignment: DM assigns a character directly to a spectator (rather than the spectator disconnecting and re-joining as a player).
- Rich spectator client: dedicated LiveView with replay scrubbing, multi-PC panel, picture-in-picture. Would justify a separate mount at that point.

## Implementation Issues

- [#121](121-spectator-membership-model.md) — Campaign membership: spectator role, invite flow, `invited_by_user_id`
- [#122](122-spectator-session-view.md) — Spectator session view: shared GameLive mount, full-map default, PC-perspective toggle, count display

**Acceptance criteria**
- [x] All open questions answered with a clear design decision and rationale
- [x] Role data model defined: `membership_role` enum extension, `invited_by_user_id` tracked
- [x] Session visibility scope defined: full map by default, PC-perspective toggle client-side
- [x] LiveView strategy decided: shared mount with conditional rendering
- [x] Follow-up implementation issues opened: #121, #122
