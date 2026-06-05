# #37 · Runtime entity map: `action_economy`, `resources`, `conditions` fields

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-05
**Priority:** high
**Tags:** architecture, rules

The runtime entity map in `Engine.State` has no action economy, no resource
pools, and no conditions. These are required for any correct combat turn:
without them, the engine cannot track whether an entity has used its action,
cannot consume spell slots, and cannot apply conditions.

These fields live in `Engine.State` (in-memory only) until persistence is
addressed in #12.

**Acceptance criteria**
- [x] `State.from_campaign/1` hydrates each entity map with `action_economy`, `resources`, and `conditions` using `DnD5e.initial_resources/1` and `DnD5e.initial_action_economy/1`
- [x] `action_economy` shape: `%{action: :available | :spent, bonus_action: :available | :spent, reaction: :available | :spent, movement_remaining: integer()}`
- [x] `resources` shape: `%{spell_slots: %{level => remaining}, ...class-specific keys}`; initialised from entity class + level
- [x] `conditions` is a list of condition refs projected from the scene `active_effects` registry (empty at start)
- [x] `State.advance_turn/1` resets `action_economy` and `movement_remaining` for the entity whose turn begins
- [x] `mix precommit` passes
