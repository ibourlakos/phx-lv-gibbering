# #163 · Engine decomposition Phase 1 — `ruleset_state: term()` opaque field

**Status:** closed
**Opened:** 2026-06-29
**Closed:** 2026-06-30
**Priority:** medium
**Tags:** architecture

Add an opaque `ruleset_state: term()` field to `Engine.State` and move all D&D-specific fields into a `%Rulesets.DnD5e.RulesetState{}` struct stored there. This is the single highest-value structural change in the decomposition plan — it removes 10 D&D fields from the engine struct without changing any external API.

Derived from [`docs/architecture/engine-decomposition.md`](../architecture/engine-decomposition.md). Requires Phase 0 (#162) to complete first.

**Fields to move out of `Engine.State` into `DnD5e.RulesetState`:**
`phase`, `previous_phase`, `active_effects`, `initiative_values`, `hidden_entities`, `session_log`, `open_container_id`, `awaiting_roll`, `pending_roll`, `pending_initiative_rolls`

**Fields that stay in `Engine.State`:**
`campaign_id`, `map_id`, `x_extent`, `y_extent`, `tile_size`, `grid_tiles`, `entities`, `turn_order`, `active_index`, `actor_id`, `valid_moves`, `valid_move_costs`, `valid_targets`, `ruleset`, and the new `ruleset_state`

**Contract:**
- The engine must never inspect the fields of `ruleset_state` directly
- Every `Ruleset` callback receives the full `%State{}` and returns `{events, new_state}` where the ruleset reads/writes `state.ruleset_state` freely
- `SceneServer` passes `ruleset_state` through without touching its structure

**Acceptance criteria**
- [x] `Gibbering.Rulesets.DnD5e.RulesetState` struct exists with the 10 moved fields
- [x] `Engine.State` no longer declares those 10 fields; `ruleset_state: term()` is present
- [x] No engine module (`SceneServer`, `Rules`, `Engine.*`) accesses `ruleset_state` fields by name
- [x] All `DnD5e` ruleset callbacks access their state via `state.ruleset_state`
- [x] `Engine.State` tests updated; `DnD5e.RulesetState` tests added for field initialization
- [x] `mix precommit` passes
