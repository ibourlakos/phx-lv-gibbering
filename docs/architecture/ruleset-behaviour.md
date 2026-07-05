# The Ruleset Behaviour

The engine is ruleset-agnostic. `GibberingEngine.Ruleset` is a **behaviour** (not a protocol — #14 resolved).
`Engine.State.ruleset` holds the module reference; `Engine.SceneServer` delegates all rule decisions to it.

```elixir
defmodule GibberingEngine.Ruleset do
  @callback collect_modifiers(entity, action, state) :: [GibberingEngine.RuleModifier.t()]
  @callback initial_resources(entity) :: map()
  @callback initial_action_economy(entity) :: map()
  @callback advance_turn(entity) :: entity
  # Vision — see features/fog-of-war.md
  @callback vision_range(entity) :: non_neg_integer() | :unlimited
  @callback vision_type(entity) :: :normal | :darkvision | :blindsight | :truesight | :tremorsense
end
```

`Engine.State` holds the ruleset module as a plain field (default `GibberingTales.Rulesets.DnD5e`).
All `DnD5e.*` subsystems live under `GibberingTales.Rulesets.DnD5e.*` (Stats, Spell, Condition).
`RuleModifier` is engine-generic and lives at `GibberingEngine.RuleModifier` (Phase 0).

## State must stay generic

Entity stats are `stats: map()`, not typed fields, so any ruleset can store what it needs:

- D&D 5e: `%{"strength" => 16, "dexterity" => 14, "spells" => ["fire_bolt", "magic_missile"]}`
- Cyberpunk (hypothetical): `%{"hacking_skill" => 7, "reflexes" => 9}`

The `GibberingTales.Data.{Races,Classes,Spells}` modules provide static lookup tables that inform stat calculation at character creation time (in the lobby). They are not invoked at runtime by the engine.
