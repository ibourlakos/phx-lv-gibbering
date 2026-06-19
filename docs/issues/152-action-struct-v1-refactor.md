# #152 · Unify weapon attack and spell resolution under `%Action{}` — v1 refactor
**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** architecture, rules, gameplay

Unify the existing two separate action paths (weapon attacks via `Rules.attack/5` and
spells via `Rules.cast_spell/5`) under a single `%Action{}` struct. This is the v1 scope
from brainstorm #19. No new action types are added — this is a structural refactor.

**`%Action{}` struct (v1):**
```elixir
%Action{
  key:          atom,         # :attack, :fireball, :magic_missile, …
  name:         string,
  description:  string,

  economy_slot: :action | :bonus_action | :reaction | :free | :movement,
  resolution:   :attack_roll | :saving_throw | :contest | :auto | :none,
  delivery:     :melee | :ranged | :touch | :self | :none,
  target_area:  %{shape: atom(), size: pos_integer() | nil},
  targeting:    :single_entity | :multi_entity | :aoe_point | :aoe_direction
              | :self | :adjacent_interactable | :none,
  charges:      pos_integer() | nil,

  source:       :weapon | :spell | :class_feature,
  effect:       term()
}
```

**Weapon attacks:** derived from `entity.stats["equipped_weapon"]` at action-bar render
time → produce an `%Action{source: :weapon, resolution: :attack_roll}`.

**Spells:** `Spell` struct is extended to produce an `%Action{}` for engine resolution.
`Spell` retains school, level, components, concentration, and slot consumption as
spell-specific fields.

**Fix `effect.attack_type` misuse:** `:aoe` is a shape, not an attack type. Remove `:aoe`
from `attack_type` — shape lives on `target_area.shape` exclusively.

**New action type — Grapple:**

Grapple is the proof-of-concept for `:contest` resolution and the first non-attack/spell
action through the unified pipeline:

- `resolution: :contest` — both parties roll d20 + ability mod; higher wins (ties: defender)
- Grappler rolls Athletics; target rolls Athletics or Acrobatics (target's choice)
- On grappler win: target gains `grappled` condition
- On target win: nothing happens; the attempt fails
- Economy slot: `:action` (uses the Attack action — can be used in place of one weapon attack)
- Target: `:single_entity` in reach (5 ft)

**Out of scope:** reactions, Ready, improvised actions, social actions, predicate-based
action discovery, Shove (follow-on to Grapple once `:contest` is wired).

**Acceptance criteria**
- [ ] `%Action{}` struct defined in `Gibbering.Engine.Action`
- [ ] `Rules.attack/5` updated to accept or produce an `%Action{}` (or replaced by a unified resolver)
- [ ] `Rules.cast_spell/5` produces an `%Action{}` for its resolution step
- [ ] `Spell.effect.attack_type` no longer contains `:aoe`; all callers updated
- [ ] Existing weapon attack and spell tests pass unchanged
- [ ] `economy_slot: :reaction` is present in the struct but no reaction logic is wired
- [ ] `resolution: :contest` implemented: both parties roll d20 + ability mod, higher wins
- [ ] Grapple action defined with `resolution: :contest`, `source: :class_feature`
- [ ] Successful grapple applies `grappled` condition to target
- [ ] Failed grapple produces no state change
- [ ] Grapple available in action bar when entity has an action available and target is in reach
