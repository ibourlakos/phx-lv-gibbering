# 12 — Player & DM Full App Experience

## Context

Currently the app has a lobby + game session flow, and a DM prep view at `/campaigns/:id/prep`.
This brainstorm defines the full experience both player types need end-to-end: campaign ownership, character creation, and a minimal but complete DM session toolset.

---

## Player Side — Campaign & Character Creation

A "player" in this context means anyone who intends to join a game as a PC (player character).

### Campaign Discovery / Joining
- Players need a way to discover or be invited to campaigns
- Options: invite link / code, DM-pushes invite, email
- What does "joining a campaign" mean at the data level? (a campaign membership record)
- Players should be able to see their active campaigns and their characters per campaign

### Character Creation
- Characters are scoped to a campaign (or portable — to decide)
- Minimum creation fields: name, race, class, background, ability score method (standard array / point buy / rolled)
- Appearance: token art, colors, body shape choices (ties into brainstorm #11 content workflow)
- Class-specific choices: starting equipment, skill proficiencies, subclass (if applicable at level 1)
- Character sheet view (read-only in game, editable in prep)
- Where does leveling up live? (out of scope for now but flag it)

### Pre-Session Prep (Player)
- Review / edit character sheet before session
- See who else is in the campaign
- See session schedule (if we add scheduling — defer for now)

---

## DM Side — Campaign Management

### Campaign Creation
- DM creates a campaign: name, description, starting map, ruleset variant (if any)
- DM is the owner; ownership transfer is out of scope for now
- DM can manage campaign membership: invite, remove, view characters

### Inviting Players & Spectators
- Invite mechanism options: shareable link (token-based), direct invite by username/email
- Spectators: can observe a session live but have no in-game actions
- Spectator vs. player distinction: separate roles, separate lobby slots?
- Should spectators see the full map (including fog of war areas the DM sees) or only the player view?

---

## DM Side — Session (Game) Controls

This is the minimum viable DM toolset needed to run a live session.

### Session Lifecycle
- Start session (transitions lobby to active game)
- Pause session — all player inputs frozen, a "paused" banner shown to players
- Resume session
- End session — archive state, return to lobby or campaign overview

### Map Control Overrides
- DM can move any entity on the map: PCs (override), NPCs, monsters, objects
- Move should bypass turn order and action economy (it's a DM override, not a game action)
- Visual distinction when DM is moving a PC (so players know it's an override)
- DM can place / remove entities mid-session (spawning monsters, placing items)
- DM can reveal / hide fog of war zones independently of player position

### Turn & Initiative Management
- DM controls initiative order (can reorder, add/remove entries mid-combat)
- DM can skip a turn (e.g., player AFK) or force end a player's turn
- DM can roll initiative on behalf of absent player

### Intervention Toolset
- Direct message / whisper to a specific player (in-app, not chat — more like a DM note popup)
- Broadcast message to all players (narrative text, ambient description)
- Apply a condition to any entity (e.g., poisoned, prone) outside of normal game flow
- Adjust HP of any entity directly (damage / heal override)
- Temporarily hide an entity from player view without removing it from state

### DM-Only View vs. Player View
- DM sees full map, all entity HP, all conditions, fog of war cleared
- DM panel should not bleed into the player's viewport (separate LiveView mount or conditional rendering)

---

## Open Questions

- Are characters campaign-scoped or account-global (portable across campaigns)?
- Do spectators get a separate LiveView or share the player view with action controls hidden?
- Invite mechanism: link/token only, or do we need username lookup?
- Should DM map overrides be logged in session history (for post-session review)?
- Where does the DM broadcast/whisper UI live — modal, sidebar, or floating panel?
- Pause behavior: does the server halt tick processing, or just reject player inputs?
- Does character creation happen inside the app or is it always done at the DM prep screen?
- What is the minimum set of character creation choices to unblock a first real playtest session?

---

## Cross-References

- Brainstorm #11 — game content workflow (race/class/background data needed for character creation)
