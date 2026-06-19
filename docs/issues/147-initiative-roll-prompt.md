# #147 · Initiative roll prompt
**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-19
**Priority:** medium
**Tags:** gameplay, rules, architecture

When the scene transitions to `:initiative_rolling`, each PC whose `auto_roll` is `false`
should be prompted to roll their initiative die, using the same `%Events.RollRequired{}`
infrastructure introduced by #146. Until the player submits (or the 60s timeout fires),
that entity's initiative is in a pending state.

This is the natural completion of the "player controls their own dice" story started
by #145/#146 — initiative is the first roll in every combat and should be consistent
with the rest of the roll-prompt UX.

**Depends on:** #146 (RollRequired struct + SceneServer `:awaiting_roll` state)

**Acceptance criteria**
- [x] When phase enters `:initiative_rolling`, a `%Events.RollRequired{roll_type: :initiative}` is emitted for each PC whose `auto_roll` is `false`
- [x] SceneServer blocks `end_initiative_rolling` until all pending initiative rolls are resolved (submitted or timed out)
- [x] Timeout behaviour matches #146: 60s, then auto-roll fires
- [x] DM and NPC entities always auto-roll initiative (no prompt)
- [x] `roll_type` atom `:initiative` is added to the type union in `%Events.RollRequired{}`

**Implementation notes**
- `pending_initiative_rolls: %MapSet{}` added to `Engine.State` to track hero entity IDs still awaiting input
- Specialized `handle_call({:transition_phase, :initiative_rolling, false})` clause in SceneServer emits `RollRequired` per hero and starts 60s `{:initiative_timeout, entity_id}` timers
- `end_initiative_rolling/1` returns `{:error, :pending_rolls}` if MapSet is non-empty
- Due to data model gap (Entity.id ≠ CampaignCharacter — no direct link), all hero entities emit `RollRequired`; client filters auto-submit based on `@auto_roll` assign
- "Start Combat" button in DM initiative panel disabled while `pending_initiative_rolls` non-empty
