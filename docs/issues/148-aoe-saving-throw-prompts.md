# #148 · AoE saving throw prompts — multi-owner concurrent rolls
**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** gameplay, rules, architecture

When an AoE effect (e.g. Fireball) targets multiple entities, each affected PC whose
`auto_roll` is `false` should be prompted for their own saving throw. This requires
concurrent pending-roll state: multiple entities awaiting a roll simultaneously,
rather than the single-entity serial flow introduced by #146.

The server must hold the AoE resolution in a pending state until all affected players
have submitted (or timed out), then apply results and emit effects in a single batch.

**Depends on:** #146 (RollRequired + pending-roll infrastructure)

**Open questions (from brainstorm #28)**
- How to handle partial timeouts: if player A times out but player B hasn't, does the
  server partially resolve or wait for all?
- UI: are multiple simultaneous roll-prompt overlays shown (one per affected PC in the
  same session), or does the prompt serialise per player?

**Acceptance criteria**
- [ ] `SceneServer` supports a `pending_rolls: %{entity_id => roll_spec}` map (not a single boolean flag)
- [ ] AoE resolution is held until all pending saving throw rolls in the map are resolved
- [ ] Each affected PC with `auto_roll: false` receives a `%Events.RollRequired{roll_type: :saving_throw}` event
- [ ] Partial resolution: if a player times out, their result auto-rolls and is removed from pending map; remaining players continue
- [ ] DM-controlled entities always auto-roll; they are not added to the pending map
