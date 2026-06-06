# #95 · DM intervention toolset (broadcast, whisper, condition/HP override)
**Status:** open
**Opened:** 2026-06-06
**Priority:** medium
**Tags:** ui, gameplay, architecture

The DM needs a minimal set of direct-intervention tools to manage narrative and combat state without going through normal game flow.

Required tools:
- **Broadcast message** — narrative text or ambient description sent to all players as a non-modal notification/banner
- **Whisper** — a private message delivered as a popup to a specific player only (not visible to others)
- **Apply condition** — attach a condition (e.g., poisoned, prone, stunned) to any entity outside of normal rules processing
- **Adjust HP** — directly set or delta-adjust HP on any entity (damage/heal override)
- **Toggle entity visibility** — temporarily hide an entity from player fog-of-war view without removing it from game state

**Acceptance criteria**
- [ ] Broadcast UI: text input + send button; all player LiveViews show the message as a dismissable banner
- [ ] Whisper UI: player selector + text input; only the targeted player's socket receives the message
- [ ] Condition apply: entity selector + condition picker; condition is added to the entity's active effects
- [ ] HP adjust: entity selector + delta or absolute input; HP is updated and broadcast
- [ ] Entity visibility toggle: entity selector + toggle; hidden entities disappear from player view but remain in DM view
- [ ] All interventions are logged in session history (who did what, when)
