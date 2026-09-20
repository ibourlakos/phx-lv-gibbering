# #189 · `state_snapshot` broadcasts full unfiltered state to every subscriber

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** security, architecture, gameplay

`broadcast_batch/3` builds `%EventBatch{..., state_snapshot: state}` with
the full, unfiltered `%State{}` and broadcasts it over the single shared
campaign PubSub topic — every subscriber (DM and all players alike)
receives the identical full state, including DM-hidden entities' actual
positions and HP. `GameLive`'s `EventBatch` handler assigns
`batch.state_snapshot` to `:game_state` unconditionally for every
connected LiveView, regardless of `viewer_role`.

Filtering currently only happens at render time
(`game_live.html.heex`'s `visible_entities` computation rejects hidden
entities only when `not @is_dm`) — this is render-layer filtering of an
already-fully-populated assign, not broadcast-time redaction. The raw data
is present in every connected socket's state and sits in the PubSub
message payload itself.

Related to #166 (closed) — #166 covered enforcement testing for `:dm_only`
*events* not appearing in a player's rendered feed. This is a distinct
vector: the *state snapshot* accompanying every batch, independent of
individual event visibility tags. #166's closure does not cover this gap.

Reach: a player opening browser devtools can see the DM's fog of war
(hidden monster positions/HPs) directly in the LiveView socket assigns or
the PubSub payload, without needing any UI bug. Low urgency at current
friends-game scale, real before any wider exposure.

**Acceptance criteria**
- [ ] `state_snapshot` (or its equivalent) is filtered per-subscriber role
      before/at broadcast time, not only at render time — e.g. a
      per-role projection computed at the SceneServer/EventBus boundary
- [ ] Regression test at the LiveView or PubSub boundary: a player-role
      subscriber's received message does not contain a DM-hidden entity's
      true position/HP, even before template rendering
- [ ] Consider cross-referencing/reopening #166 if its original
      acceptance criteria are read as covering this
- [ ] `mix precommit` passes

**Source:** identified via external code review (GLM/ZAI), verified
against code before filing.
