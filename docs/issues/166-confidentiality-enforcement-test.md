# #166 · Confidentiality enforcement — assert player subscriber cannot receive `:dm_only` events

**Status:** open
**Opened:** 2026-06-29
**Priority:** high
**Tags:** security, architecture, ops

No test currently asserts that a player-role LiveView subscriber does **not** receive `:dm_only` events. The event visibility taxonomy (`event.visibility = :dm_only | :public | :revealed`) was established in #136 and the CQRS projection work (#113) was completed, but there is no Layer 3 enforcement test that proves the contract holds at the LiveView boundary.

If DM-only events travel over the wire to player sockets, players could observe DM-internal state (hidden HP values, un-revealed NPCs, pending roll targets) through browser dev tools.

**Test approach:**
1. Mount `GameLive` as a player-role user
2. Trigger a state change that emits a `:dm_only` event (e.g., DM adjusts a hidden NPC's HP, or a `SessionEnded` with DM-only metadata)
3. Assert the event does not appear in the player's rendered event feed
4. Assert no SVG `data-*` attribute exposes the hidden information

**Acceptance criteria**
- [ ] At least one Layer 3 (LiveView) test explicitly asserts player mount does not receive/render a `:dm_only` event
- [ ] Test covers both the event feed UI and any SVG element attributes
- [ ] If the test reveals the gap is real (events do leak), open a follow-up bug issue before closing this one
- [ ] `mix precommit` passes
