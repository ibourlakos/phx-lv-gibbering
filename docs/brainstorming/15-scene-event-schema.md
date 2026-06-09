# Brainstorm #15 — Scene event schema and Published Language

**Status:** open

## Context

WP-J issues #108 (EventBus behaviour), #111 (event cascade batch emission), and #113 (CQRS read model formalization) all depend on knowing what typed event structs flow across the event bus (E). Currently the system broadcasts bare tuples — `{:state_updated, state}`, `:session_ended`, `{:dm_broadcast, text}` — where `{:state_updated, state}` ships the entire internal `Engine.State` to every subscriber.

This is not a Published Language. The polytope treatise (§8.5) names the intended scene events: `DamageDealt`, `ConditionApplied`, `EntityMoved`, `TurnAdvanced`, `PhaseTransitioned`. Before the EventBus port can be specified and the batch emission pattern designed, the following questions must be settled.

**Cross-references:** #106 (event schema design methodology), #108, #111, #113.

---

## Open questions

### 1. Replace or coexist with `{:state_updated, state}`?

Currently every mutation broadcasts the full `Engine.State`. LiveView subscribes and re-renders the entire game board from it. Two options:

- **Replace** — replace `{:state_updated, state}` with a batch of typed events per command; LiveView projects them into local state. Clean Published Language, but LiveView must maintain its own projection rather than receiving ready-to-render state.
- **Coexist** — keep `{:state_updated, state}` for the Web Adapter (it's a convenience projection), and also emit typed events for all other subscribers (Observability, future event log, spectator feed). Two distinct bus messages per command, but LiveView migration cost is deferred.

Which model do we adopt?

### 2. What are the canonical scene event types?

The treatise names five. Are they the right set, and are they granular enough?

| Proposed event | Triggered by | Key payload fields |
|---|---|---|
| `EntityMoved` | `move_entity` | entity_id, from: {x,y}, to: {x,y}, cost_ft |
| `AttackResolved` | `attack_entity` | attacker_id, target_id, roll, hit?, damage |
| `DamageDealt` | attack or spell that hits | target_id, amount, damage_type, new_hp |
| `ConditionApplied` | attack effect, DM apply | entity_id, condition_id, source_id, duration |
| `ConditionRemoved` | end of duration, save, DM | entity_id, condition_id, reason |
| `TurnAdvanced` | `end_turn`, `force_end_turn` | from_entity_id, to_entity_id, round_number |
| `PhaseTransitioned` | `transition_phase` | from_phase, to_phase |
| `SpellCast` | `cast_spell` | caster_id, spell_key, target_id, outcome |
| `ResourceConsumed` | spell slot use, rage | entity_id, resource_key, amount_used, remaining |
| `SessionEnded` | `end_session` | campaign_id |

Are `AttackResolved` and `DamageDealt` separate events or one? (They are separate in real 5e: a miss produces an attack event but no damage event.)

Are there DM-intervention events (`HPAdjusted`, `VisibilityToggled`) or are those projected differently?

### 3. What fields belong in each event vs what is derivable?

The event schema is a Published Language contract — changing field names or types is a breaking change. Guideline: include the minimum fields that every subscriber needs; do not include fields that require knowledge of another context's internal model.

- Should events carry denormalized entity names (e.g. `attacker_name: "Aldric"`) for display, or only IDs?
- Should `DamageDealt` carry `new_hp` (post-damage HP) or only `amount`? Post-damage HP is convenient for the Web Adapter but requires SceneServer to include it, coupling the event to the current state snapshot.
- Should events carry a `causation_id` linking a child event to the parent command that triggered it?
- Should events carry a `sequence_number` for total ordering within a command's batch?

### 4. Cascade batch structure

Issue #111 proposes the Event Aggregator pattern: SceneServer emits a causally ordered batch per command rather than individual events. What is the batch envelope?

Options:
- `{:events, [event1, event2, ...]}` — bare list wrapped in a tuple, same PubSub topic.
- `%EventBatch{command: atom, events: [event], sequence: integer}` — typed struct with metadata.
- Keep individual events but add a `batch_id` field to each — subscribers can reassemble the batch if they care.

Which structure best serves the Web Adapter (animation sequencing), Observability (metrics), and future event log (replay)?

### 5. What happens to `{:dm_broadcast, text}` and `{:whisper, text}`?

These are notification events, not scene-domain events. They belong to the Notification context (#107 assigned `Gibbering.Notification`). Should they:
- Stay as bare tuples on the same game topic (current behaviour)?
- Move to a dedicated notification topic?
- Become typed notification event structs?

### 6. Module location for event struct definitions

Where do the event struct modules live?

- `Gibbering.Engine.Events.*` — owned by the Scene context; other contexts depend on it.
- `Gibbering.Events.*` — top-level, treated as the Published Language registry shared by all contexts.
- Inline in `Gibbering.EventBus` — co-located with the bus port definition.

The polytope treatise (§3.2) is explicit: the event schema registry is the most important contract in the system. It should be treated as a top-level concern, not owned by any single bounded context.

---

## Issues to open after settling

_(Fill in after decisions are made)_

- Scene event struct definitions (typed structs + field specs)
- EventBus behaviour port (#108 — unblocked once event types are known)
- Update `SceneServer` broadcast calls to emit typed events (or coexist pattern)
- Any notation in `docs/architecture.md` for the Published Language registry location
