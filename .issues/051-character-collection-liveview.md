# #51 · Character collection LiveView
**Status:** open
**Opened:** 2026-06-05
**Priority:** high
**Tags:** gameplay, rendering

Add a `/characters` top-level route and LiveView that shows the current user's personal character roster. This is the player's home for browsing, creating, and managing their characters independently of any campaign.

The page is accessible to users with the `"player"` role. DMs may also have characters.

Each character card in the roster shows: character name, race, class, level, and their appearance sprite (composable SVG — see #53). A "New Character" button opens the creation modal (see #52). Cards have edit and delete affordances.

**Acceptance criteria**
- [ ] `/characters` route added to the router, protected by authentication
- [ ] `GibberingWeb.CharactersLive` LiveView renders the user's character roster
- [ ] Empty state shown when the user has no characters yet
- [ ] Each character card displays name, race, class, level, and appearance preview
- [ ] Delete with confirmation removes the character (and validates it is not active in any campaign)
- [ ] `mix precommit` passes
