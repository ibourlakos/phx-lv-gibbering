# #92 · Spectator role — campaign membership and session view (discovery)
**Status:** open
**Opened:** 2026-06-06
**Priority:** low
**Tags:** discovery, architecture, gameplay

Spectators can observe a live session but have no in-game actions. Decide the full design before any implementation.

Open questions to resolve:
- Is spectator a distinct campaign membership role, or a session-join mode for any user?
- Does a spectator share the player LiveView (with action controls hidden) or get a separate LiveView mount?
- What does a spectator see: full map (DM view) or player-limited fog-of-war view? Is it configurable per campaign?
- Are spectators visible to players (a "spectators watching" count) or silent?
- Can a spectator be upgraded to a player mid-campaign (e.g., a late joiner)?
- Does the spectator count affect session server process design (PubSub topic subscription vs. full GameServer client)?

**Acceptance criteria**
- [ ] All open questions above answered with a clear design decision and rationale
- [ ] Role data model defined: whether it's a `membership_role` enum extension or a separate table
- [ ] Session visibility scope defined (what state a spectator receives vs. a player)
- [ ] LiveView strategy decided: shared mount with conditional rendering, or separate mount
- [ ] Decision captured in a follow-up implementation issue (or this issue upgraded to implementation)
