# 12 — Player & DM Full App Experience

**Status:** settled

## Context

Currently the app has a lobby + game session flow, and a DM prep view at `/campaigns/:id/prep`.
This brainstorm defines the full experience both player types need end-to-end: campaign ownership, character creation, and a minimal but complete DM session toolset.

---

## Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Campaign membership model | `CampaignCharacter` join record: portable `characters` table + campaign-scoped membership; character sheet is editable in prep, read-only in session (#54, closed) |
| 2 | Invite mechanism | Link/token only — no username/email lookup in the first pass; shareable URL contains a short-lived token (#91, closed) |
| 3 | Spectator role design | Deferred to discovery phase — requires a full design decision on LiveView strategy (shared mount vs. separate), visibility scope (player fog vs. DM fog), and lobby slot model (#92, open) |
| 4 | Session lifecycle | Server-side control: start transitions lobby → active, pause rejects player inputs on the server (not just UI-frozen), resume re-enables them, end archives state (#93, closed) |
| 5 | DM initiative management | DM can reorder, add/remove initiative entries, skip/force-end turns, roll on behalf of absent players; own panel component (#94, closed) |
| 6 | DM intervention toolset | Broadcast/whisper messages, apply conditions, adjust HP, hide/show entities — all out-of-turn DM overrides; separate from normal game action flow (#95, closed) |
| 7 | Player campaign overview | Dedicated `/campaigns` page listing active campaigns and character per campaign; entry point to join or prep (#90, closed) |
| 8 | Character creation location | In-app creation flow, accessible from the player campaign overview; not embedded in the DM prep screen |
| 9 | Leveling up | Explicitly out of scope for now; flag for a future brainstorm |
| 10 | Session scheduling | Deferred indefinitely |
| 11 | DM override logging | Partial: HP and condition overrides noted in #95 ACs; full session history design deferred to a future issue |

---

## Cross-References

- Brainstorm #11 — game content workflow (race/class/background data needed for character creation)
- Issue #92 — spectator role (open discovery issue derived from this brainstorm)

---

## Issues

_Triaged 2026-06-06, settled 2026-06-12_

| # | Title | Status |
|---|---|---|
| [#90](../issues/090-player-campaign-overview-page.md) | Player campaign overview page | closed |
| [#91](../issues/091-campaign-invite-link-token.md) | Campaign invite link / shareable token mechanism | closed |
| [#92](../issues/092-spectator-role-discovery.md) | Spectator role — membership and session view (discovery) | open |
| [#93](../issues/093-dm-session-lifecycle-controls.md) | DM session lifecycle controls (start, pause, resume, end) | closed |
| [#94](../issues/094-dm-initiative-panel.md) | DM turn and initiative management panel | closed |
| [#95](../issues/095-dm-intervention-toolset.md) | DM intervention toolset (broadcast, whisper, condition/HP override) | closed |
