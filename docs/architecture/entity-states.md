# Entity State Vocabulary

Reference for every state an entity can be in, grouped by category. Each entry declares its
**visual impact tier** so art assets can be authored at the right granularity.

Visual impact tiers:
- **Tier 1** — requires a separate appearance record (different `state` key in the `appearances` table)
- **Tier 2** — rendered as an SVG badge/overlay on the existing sprite (see `docs/architecture/features/active-effects.md`)
- **Tier 3** — panel information only; no map visual

---

## Vitality States

HP-driven states computed from `entity.hp` and `entity.max_hp` at render time.

| State | Condition | Visual Tier | Notes |
|---|---|---|---|
| `alive` | hp > 50% of max_hp | — | Default; no special treatment |
| `bloodied` | 0 < hp ≤ 50% of max_hp | Tier 2 | Red tint overlay; same base sprite |
| `dying` | hp == 0, hero, not yet stable | Tier 2 | Prone-like overlay; awaiting death save |
| `unconscious` | hp == 0 and stable, or unconscious condition | Tier 1 | Prone sprite required |
| `dead` | hp == 0, monster / object destroyed | Tier 1 | Separate appearance record (e.g. skeleton overlay, broken chest) |
| `destroyed` | objects at 0 hp | Tier 1 | Separate appearance record (broken/rubble variant) |

---

## D&D 5e Conditions

The 15 official conditions from the SRD. Applied via `ConditionApplied` / `ConditionRemoved` events
and stored in `entity.conditions`.

| Condition ID | Label | Visual Tier | Rendering Note |
|---|---|---|---|
| `blinded` | Blinded | Tier 2 | Dark overlay badge |
| `charmed` | Charmed | Tier 2 | Heart / sparkle badge |
| `deafened` | Deafened | Tier 3 | Panel only |
| `exhaustion` | Exhaustion | Tier 3 | Panel only (level 1–6 tracked in stats) |
| `frightened` | Frightened | Tier 2 | Flee-arrow badge |
| `grappled` | Grappled | Tier 2 | Chain badge |
| `incapacitated` | Incapacitated | Tier 2 | Zap badge |
| `invisible` | Invisible | Tier 1 | Translucent / ghost appearance record |
| `paralyzed` | Paralyzed | Tier 1 | Prone appearance record; distinct from unconscious |
| `petrified` | Petrified | Tier 1 | Stone-tinted appearance record |
| `poisoned` | Poisoned | Tier 2 | Green tint badge |
| `prone` | Prone | Tier 1 | Prone (horizontal) appearance record |
| `restrained` | Restrained | Tier 2 | Web / root badge |
| `stunned` | Stunned | Tier 2 | Stars badge |
| `unconscious` | Unconscious | Tier 1 | Covered by vitality state above |

---

## Game-System States (engine-specific)

States that exist in the engine but have no direct SRD analogue.

| State | Source | Visual Tier | Notes |
|---|---|---|---|
| `concentrating` | Spell with concentration ongoing | Tier 2 | Glow ring badge |
| `raging` | Barbarian rage active | Tier 2 | Flame aura badge |
| `hidden` | Stealth — hidden from opponents | Tier 2 | Stealth badge (DM only visible to players) |
| `action_spent` | Action economy marker | Tier 3 | Shown in panel / initiative strip |
| `bonus_spent` | Bonus action spent | Tier 3 | Panel only |
| `reaction_spent` | Reaction spent | Tier 3 | Panel only |
| `movement_exhausted` | No remaining movement this turn | Tier 2 | Footstep-X badge (see issue #159) |

---

## Object States

States for `type: "object"` entities (containers, scenery, fixtures).

| State | Applies to | Visual Tier | Notes |
|---|---|---|---|
| `intact` | Any object | — | Default; no special treatment |
| `damaged` | Objects with HP > 0 but below max | Tier 2 | Crack overlay badge |
| `destroyed` | Objects at 0 HP | Tier 1 | Separate appearance record (rubble, ash, splinters) |
| `open` | `loot_source` objects | Tier 1 | Open lid / lid-removed appearance record |
| `closed` | `loot_source` objects | — | Default closed appearance |
| `locked` | Containers with a lock | Tier 3 | Panel only; lock icon in inspection panel |
| `trapped` | Any object | Tier 3 | Panel DM-only indicator; not visible to players |
| `disarmed` | Formerly trapped | Tier 3 | Panel only |

---

## Authoring Rules

1. Tier 1 states require an `appearances` record with a matching `state` value (e.g.
   `content_key: "goblin", state: "dead"`). The rendering pipeline falls back to
   `state: "default"` when no state-specific record exists.
2. Tier 2 states are rendered as SVG overlays by the badge system (see
   `docs/architecture/features/active-effects.md`). No additional appearance record needed.
3. Tier 3 states surface only in the inspection panel via `inspect_content/2`. No SVG
   changes are required.
4. A single entity can have multiple simultaneous states; they are applied in layer order
   (vitality → D&D conditions → game-system states → object states).
