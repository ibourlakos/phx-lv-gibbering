# Splitting the Grimoire
### Architecture: Engine vs. Ruleset Separation

**Date:** 2026-06-03  
**Status:** Decision locked

---

## The Question

Should the Gibbering Engine be:
- A D&D-specific engine
- A generic 2D engine with D&D on top
- A platform where anyone can drop in their own ruleset

## Options Considered

**A — Clean layer separation (engine + ruleset behaviour)**  
The engine is a pure LiveView SVG grid runtime: tiles, entities, positions, events. D&D is an Elixir `behaviour` (interface) that plugs into it via callbacks. Rulesets are swappable per game session.

**B — Data-driven Virtual Tabletop**  
Rulesets are JSON/YAML documents interpreted at runtime. No Elixir needed to define rules. Most ambitious; closest to Foundry VTT.

**C — Scenario engine**  
Engine runs self-contained "scenarios" (encounter, puzzle, chase). Each is a GenServer with its own state machine. Narrower than B.

**D — Stay focused, ship D&D**  
No abstraction. The engine is the D&D engine. Clean architecture emerges via refactor, not upfront design.

## Decision: Option A

Rationale:
- The `behaviour` pattern is idiomatic Elixir — not over-engineering
- D&D 5e SRD is the concrete first implementation, so the game is still real and playable
- Different sessions can run different rulesets simultaneously with zero extra code (each `GameServer` process holds its own `ruleset` module reference)
- Can publish the engine as a Hex package later

---

## How Ruleset Swapping Works

### The Behaviour Contract

```elixir
defmodule Gibbering.Ruleset do
  @callback on_move_requested(state, entity_id, {x, y}) :: {:ok, state} | {:error, reason}
  @callback on_entity_selected(state, entity_id) :: state
  @callback on_combat_action(state, attacker_id, target_id, action) :: state
  @callback valid_moves(state, entity_id) :: [{x, y}]
end
```

### GameServer holds the ruleset module as data

```elixir
defmodule Gibbering.Engine.GameServer do
  def start_link(game_id, ruleset \\ Gibbering.Rulesets.DnD5e) do
    GenServer.start_link(__MODULE__, %{ruleset: ruleset, ...})
  end

  def handle_call({:move_requested, entity_id, pos}, _from, %{ruleset: ruleset} = state) do
    case ruleset.on_move_requested(state.game_state, entity_id, pos) do
      {:ok, new_game_state} -> # broadcast + reply
      {:error, reason}      -> # reject + flash
    end
  end
end
```

### Dropping in a custom ruleset

1. Create `MyGame.Rulesets.Cyberpunk` with `@behaviour Gibbering.Ruleset`
2. Pass it at session start: `GameServer.start_link("room-42", MyGame.Rulesets.Cyberpunk)`
3. Nothing else changes — engine, LiveView, SVG renderer are ruleset-agnostic

Multiple rooms can run different rulesets simultaneously in the same Phoenix app.

### Key constraint: keep State generic

Entity stats must be `stats: map()` (not `strength: integer()`), so any ruleset can store what it needs:

- D&D: `%{strength: 18, dexterity: 14, ...}`
- Cyberpunk: `%{hacking_skill: 7, reflexes: 9, ...}`
- Homebrew: anything

---

## Open Questions (for future brainstorm)

- Should `Gibbering.Ruleset` be a `behaviour` or a `protocol`? (Behaviour is simpler; protocol opens structural polymorphism)
- How does the ruleset declare what UI controls to show? (Action buttons, stat panels)
- Does the ruleset own the fog-of-war calculation, or does the engine always handle it?
