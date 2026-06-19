# #19 · Unified Action Model

## Context

The engine currently handles actions in two separate tracks: weapon attacks (implicit,
derived from `equipped_weapon`) and spells (explicit `Spell` struct with `target_area`,
`effect.attack_type`, etc.). This works for the current feature set but breaks down as
soon as the system needs to represent improvised attacks, environmental interactions,
social actions, DM-created on-the-fly actions, or anything that isn't a spell or a
simple weapon swing.

The key observation from brainstorm #18 (inspection panel): targeting shape and
resolution mechanism are properties of *any* action, not just spells. Throwing a chair
is not a spell.

This brainstorm maps the full D&D 5e action space and defines what a unified `Action`
model needs to express to serve the inspection panel, targeting UI, action bar, and
engine resolution pipeline.

---

## Current state

- Weapon attacks: resolved implicitly via `Rules.attack/5`; damage derived from `entity.stats["equipped_weapon"]`
- Spells: `Spell` struct carries `target_area`, `effect.attack_type`, `casting_time`, `range`; resolved via `Rules.cast_spell/5` → `do_cast/4`
- `effect.attack_type` conflates resolution mechanism with delivery shape: `:aoe` does not belong there — shape is already on `target_area.shape`. Field needs to be cleaned up.
- No general `Action` struct
- No representation for: improvised attacks, grapple/shove, Dash/Disengage/Dodge, environmental interactions, social actions, reactions, Ready

---

## Topic areas

### 1. What "realism" means in D&D

Not photorealism — verisimilitude within the game's rules. The pillars that make D&D
feel like D&D:

- **Action economy as constraint** — every turn is a meaningful choice (action, bonus action, reaction, movement, free); you cannot do everything
- **Reactions make the world responsive** — enemies can interrupt (opportunity attack when you flee), allies can intercede (Shield, Counterspell)
- **The fiction always has a path** — the DM can adjudicate any creative attempt; the system must not hard-close the door
- **Conditions chain** — grappled + shoved = prone; prone = advantage for melee attackers, which can satisfy Sneak Attack; etc.
- **Environment participates** — cover, difficult terrain, interactive objects, lighting
- **Social layer** — Persuade, Deceive, Intimidate, Insight resolve situations without combat
- **Resource depletion arc** — spell slots, HP, action economy within a turn; rest as the reset valve

For a video game the hard part is that tabletop realism comes from the DM's ability to
say yes to *anything*. A video game must enumerate the possible. The unified action
model is what defines "anything" in this engine.

---

### 2. The full D&D 5e action space

#### Action slot
| Action | Resolution | Targeting |
|---|---|---|
| Attack — weapon | `:attack_roll` | `:single_entity` |
| Attack — improvised (throw chair, punch wall) | `:attack_roll` | `:single_entity` |
| Cast Spell (1-action) | varies by spell | varies by spell |
| Dash | `:none` | `:self` (grants extra movement) |
| Disengage | `:none` | `:self` (movement won't provoke OA) |
| Dodge | `:none` | `:self` (attacks vs you have disadvantage) |
| Help | `:none` | `:single_entity` (ally gains advantage) |
| Hide | `:skill_check` (Stealth) | `:self` |
| Ready | `:none` at declaration; trigger fires action as reaction later | — |
| Search | `:skill_check` (Perception / Investigation) | `:self` |
| Use Object | `:none` | `:adjacent_interactable` |
| Grapple | `:contest` (Athletics vs Athletics/Acrobatics) | `:single_entity` in reach |
| Shove | `:contest` (Athletics vs Athletics/Acrobatics) | `:single_entity` in reach |

#### Bonus action slot
| Action | Resolution | Targeting |
|---|---|---|
| Offhand attack | `:attack_roll` | `:single_entity` in reach |
| Cast Spell (bonus-action) | varies | varies |
| Rage (Barbarian) | `:none` | `:self` |
| Second Wind (Fighter) | `:none` | `:self` |
| Bardic Inspiration | `:none` | `:single_entity` ally |
| Cunning Action (Rogue) | varies | `:self` |

#### Reaction slot
| Action | Trigger | Resolution |
|---|---|---|
| Opportunity Attack | enemy leaves melee reach without Disengage | `:attack_roll` |
| Shield (spell) | you are about to be hit | `:none` (+5 AC applied retroactively) |
| Counterspell | enemy casts a spell within 60 ft | `:skill_check` if spell level ≥ 4 |
| Uncanny Dodge (Rogue) | being attacked | `:none` (halves damage) |
| Readied action | player-defined trigger | whatever was readied |

#### Free interaction (once per turn, no economy cost)
Draw/sheathe weapon, open/close unlocked door, pick up item, hand item to ally, flip
a switch or pull a lever, turn a key in a lock.

#### Environmental / scene interaction (non-combat, context-dependent)
Loot container, Talk to NPC, Read a document, Inspect an object, Pick a lock, Disarm a
trap. These may consume an action slot in combat; outside combat they are free
narrative actions.

---

### 3. Resolution mechanisms — a closed orthogonal set

These are orthogonal to targeting shape and delivery:

| Key | Meaning |
|---|---|
| `:attack_roll` | d20 + bonus vs target AC |
| `:saving_throw` | target rolls d20 + ability mod vs actor's spell save DC |
| `:contest` | both parties roll d20 + ability mod; higher wins (ties: defender) |
| `:skill_check` | actor rolls d20 + skill mod vs fixed DC |
| `:auto` | always applies, no roll (Magic Missile, healing) |
| `:none` | action produces an effect directly without resolution (Dodge, Dash, Disengage) |

`:contest` is the new addition relative to the current Spell struct's `attack_type`.
Grapple and Shove both require it.

---

### 4. Delivery

Separate from resolution — *how/where* does the action reach its target:

| Key | Meaning |
|---|---|
| `:melee` | within reach (5 ft default; 10 ft with Reach property) |
| `:ranged` | within normal/long range bands |
| `:touch` | must be adjacent (same as melee but distinct for rule purposes) |
| `:self` | always targets the actor |
| `:none` | no delivery needed (Dodge, Disengage) |

Area shape (`:sphere`, `:cone`, `:line`, etc.) is orthogonal to delivery — delivery says
*how* you reach the target area; shape says *what is covered* once you do.

---

### 5. Targeting

| Key | Examples |
|---|---|
| `:single_entity` | most attacks, single-target spells |
| `:multi_entity` | Magic Missile (distribute N charges across targets) |
| `:aoe_point` | place center of sphere or cube |
| `:aoe_direction` | cone or line — pick direction from caster |
| `:self` | Dodge, Dash, Rage |
| `:adjacent_interactable` | Loot, Talk, Read, Open Door |
| `:none` | pure self-effect with no choosable target |

---

### 6. Improvised actions — the DM's domain

In tabletop the DM adjudicates anything: "throw the chair" → improvised ranged attack,
1d4 bludgeoning, 20 ft range. Two paths in the engine:

**A. Predefined improvised templates** — a small catalogue of generic improvised actions
(Improvised Melee Attack, Improvised Throw, Shove Object, Environmental Hazard) the DM
can invoke quickly. Each is a full `Action` struct with configurable damage dice.

**B. DM freeform action** — the DM constructs an action on-the-fly in the UI: names it,
sets resolution, targeting, dice. One-shot; not persisted to any catalogue. Produces the
same `Action` struct the engine resolves.

Both paths produce the same `Action` that flows through the same resolution pipeline.

---

### 7. Reactions and Ready — the structurally hard cases

**Reactions** require the engine to *pause mid-action* and offer another entity a chance
to respond. For an opportunity attack: Entity A moves → engine fires
`:opportunity_attack_window` → Entity B (if reaction available) is offered the attack →
resolves → original movement resumes. Options:

A. **Synchronous pause** — engine emits event, waits for player input (or auto-resolves
for NPCs/DM-controlled), then continues. Requires the action pipeline to be
interruptible at specific points.

B. **Deferred resolution** — movement completes first, OA is inserted retroactively.
Incorrect per RAW but simpler to implement for v1.

C. **Event queue with reaction slots** — actions push to an ordered queue; reactions can
insert before/after specific queue positions. Cleanest long-term; highest implementation
cost.

**Ready** requires capturing intent (the readied action definition) in state, holding it
across turns, and firing when the trigger condition is met (which may be during a
different entity's turn).

Both are out of scope for v1 but the action model must not structurally preclude them.

---

### 8. Event chaining and action-triggered actions

Some actions produce events that must trigger further actions — either immediately or
after a player decision. This is not just an edge case: it is a core D&D mechanism.

**Canonical examples:**

- **Hellish Rebuke (Warlock)**: Entity A deals damage to the Warlock → Warlock spends
  their reaction → casts Hellish Rebuke (1d10 fire, DEX save) against Entity A. The
  triggering damage event causes a new spell action to be queued and resolved.

- **Opportunity Attack**: Entity A moves out of reach → engine detects this → Entity B
  (if reaction available and within reach) may take an attack action as a reaction,
  interrupting Entity A's movement resolution.

- **Counterspell**: Entity A begins casting a spell → Entity B spends their reaction →
  Counterspell fires → if successful, Entity A's spell is cancelled before it resolves.

- **Trap triggered by AoE**: A Fireball lands on a tile with a pressure-plate trap →
  the explosion event triggers the trap → the trap emits its own damage event. Actions
  cascade without player input.

**Structural requirements this imposes on the action pipeline:**

1. Action resolution must be able to **pause at defined interrupt points** and offer
   reaction opportunities to other entities (player-controlled or DM-controlled).
2. The event system must support **chained event emission** — an event handler can enqueue
   further actions, not just state mutations.
3. Reactions must be **first-class economy items** tracked per entity per round
   (`action_economy.reaction: :available | :spent`), already in the runtime entity map.
4. The engine must distinguish between events that are **interruptible** (spell casting
   begins — Counterspell window) and **non-interruptible** (spell damage lands — no
   window after the fact).

**Relation to the event model (issues #111, #119):** the `%EventBatch{}` / Published
Language infrastructure already defines that scene events are typed structs. Chaining
means event handlers can produce new `%EventBatch{}` responses rather than only state
mutations. The action model must express which events open interrupt windows and for whom.

---

### 9. Proposed general Action struct

```elixir
%Action{
  key:          atom,          # :attack, :fireball, :throw_chair, :grapple, :dash, …
  name:         string,
  description:  string,        # shown in the detail panel and action bar tooltip

  economy_slot: :action | :bonus_action | :reaction | :free | :movement,
  resolution:   :attack_roll | :saving_throw | :contest | :skill_check | :auto | :none,
  delivery:     :melee | :ranged | :touch | :self | :none,
  target_area:  %{shape: atom(), size: pos_integer() | nil},
  targeting:    :single_entity | :multi_entity | :aoe_point | :aoe_direction
                | :self | :adjacent_interactable | :none,
  charges:      pos_integer() | nil,  # for :multi_entity — number of darts/hits

  source:       :weapon | :spell | :class_feature | :improvised | :environment,
  prerequisites: predicate(),  # reuses existing predicate vocabulary (issue #31)
  effect:       term()         # spell effect map, damage dice, condition key, etc.
}
```

`Spell` becomes a specialisation that adds school, level, components, concentration, and
slot consumption, then produces an `Action` for the engine.

Weapon attacks are generated from `entity.stats["equipped_weapon"]` at action-bar
render time, producing an `Action` with `source: :weapon`.

---

## Decisions

| Q | Decision | Deferred? |
|---|---|---|
| **Q1** | v1 keeps existing storage: spells in DB, weapons derived from `entity.stats["equipped_weapon"]`, class features implicit. Unified Action catalogue (DB table or module per entity type) is Phase 2. | Phase 2 |
| **Q2** | v1: action bar renders available actions from entity state at render time (existing approach). Predicate-based discovery (`prerequisites` evaluation) is Phase 2. | Phase 2 |
| **Q3** | `:contest` deferred until Grapple/Shove are explicitly in scope. Not modelled in v1. | Deferred |
| **Q4** | v1 scope: unify the existing weapon attack (`Rules.attack/5`) and spell (`Rules.cast_spell/5`) paths under the `%Action{}` struct. Fix the `effect.attack_type` `:aoe` misplacement (shape is on `target_area.shape`, not `attack_type`). No new action types. | No |
| **Q5** | DM freeform improvised actions deferred with #85 (content creation tools). | Deferred (#85) |
| **Q6** | `economy_slot: :reaction` in the struct already accommodates reactions. No interrupt pipeline designed in v1 — reactions remain a stub. | Phase 2 |
| **Q7** | Social/exploration actions are a separate non-combat interaction layer, not part of the `%Action{}` combat pipeline in v1. | Deferred |
| **Q8** | No interrupt points in v1. Opportunity attacks, Counterspell, and reaction triggers are all deferred. | Phase 2 |
| **Q9** | Trap-triggered event chaining deferred with trap mechanism design (#85). | Deferred (#85) |

## Issues Opened

| Issue | Title | Status |
|---|---|---|
| [#152](../issues/152-action-struct-v1-refactor.md) | Unify weapon attack and spell resolution under `%Action{}` — v1 refactor | open |

This brainstorm will be deleted when #152 is closed. Phase 2 questions (catalogue, predicate discovery, reactions, interrupt pipeline) should be addressed in a follow-on brainstorm at that time.
