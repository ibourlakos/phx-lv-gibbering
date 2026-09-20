# #182 · Nil-target crash paths in attack/spell/condition handlers

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** bug, architecture

Several call sites fetch an entity by id from `state.actors` and use it
unguarded, so a stale or unknown `target_id`/`entity_id` (e.g. a target
destroyed between render and click) crashes the process instead of
returning an error. Violates CLAUDE.md's "handle stale IDs gracefully"
guideline (see also the `SceneServer`/`GenServer` start_link guidance in
CLAUDE.md, same principle).

Confirmed sites:

1. `SceneServer.handle_call({:attack, target_id, auto_roll}, ...)` — fetches
   `target = state.actors[target_id]` unguarded. If `not auto_roll`,
   `target.name` is accessed directly before validation. If `auto_roll`,
   the possibly-nil `target` is passed into `Rules.do_attack/4`, which does
   `Map.get(target, :armor_class, 10)` → `Map.get(nil, :armor_class, 10)`
   raises `BadMapError`.
2. `SceneServer.handle_call({:cast_spell, ...})` — same pattern via
   `Rules.do_cast/4`.
3. `GameLive.handle_event` (`game_live.ex:268`) —
   `state.actors[target_id].name` with no nil guard.
4. `SceneServer` DM condition application → `State.apply_condition/4` →
   `Map.update!(state.actors, entity_id, ...)` raises `KeyError` on an
   unknown `entity_id`.

Any of these crashes the `SceneServer` GenServer and it restarts from last
persist, dropping in-flight scene state for all connected players.

**Acceptance criteria**
- [ ] All four sites return `{:error, :not_found}` (or equivalent no-op)
      instead of raising when the referenced entity is missing
- [ ] Regression test per site proving a stale/unknown id no longer crashes
      the process
- [ ] `mix precommit` passes

**Source:** identified via external code review (GLM/ZAI), verified against
code before filing.
