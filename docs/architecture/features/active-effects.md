# Active Effect Visuals and Animation

Resolved in #34. Four design decisions cover the full lifecycle.

## Static visual representation

Visual metadata for active effects is declared in the Ruleset via a new `effect_visual/1` callback — not stored on the `ActiveEffect` struct. The engine struct remains pure data. The SVG pipeline queries `state.ruleset.effect_visual(condition_id)` at render time and receives a tagged tuple:

```elixir
{:entity_badge, color: "#8b0000", icon: :skull}
{:area_overlay, shape: :sphere, radius: 2, fill: "rgba(0,100,0,0.3)"}
{:effect_entity, sprite: "spiritual_weapon"}
:none
```

The layer stack gains two new layers:
- **Layer 2b** (between decorations and move overlay): area effect `<g>` overlays.
- **Layer 4b** (above entity sprite, below selection ring): entity condition badges (coloured dots / icons per condition).

Effect-entities (`{:effect_entity, …}`) are injected into the Layer 4 depth-sort list as virtual entities, sharing the existing sprite rendering path.

## Animation triggers

Animations are data-driven, delivered via a new `EffectAnimation` JS hook on `#game-board` (same pattern as `DiceRoll`). When a scene event requires a visual animation, the LiveView pushes:

```elixir
push_event(socket, "play_effect_animation", %{
  type: "condition_applied",
  condition: "poisoned",
  target_id: entity_id,
  duration_ms: 800
})
```

The hook maps `type` → a CSS class applied to the target SVG `<g>` for `duration_ms`. The type→class manifest is a static object in `app.js`.

## Cascade sequencing

The LiveView serialises animation chains server-side using a `pending_animations` list in socket assigns and `Process.send_after`. When `SceneServer` publishes `{:scene_events, [e1, e2, …]}`, the LiveView plays `e1` immediately via `push_event/3`, then schedules `Process.send_after(self(), :advance_animation_queue, e1.duration_ms)`. `handle_info/2` pops and plays the next event in sequence. No client ACK needed.

## Sustain animation lifecycle

Looping/pulsing sustain animations (Concentration, Rage) use CSS `@keyframes` classes toggled by LiveView diffs. Each entity `<g>` contains `<g class="effect-overlays">`. The renderer adds condition-specific classes (e.g. `"anim-pulse-concentration"`) when the condition is in `entity.conditions`; they are removed on the next diff when the condition clears. The browser starts/stops the `@keyframes` animation automatically — no explicit JS lifecycle management.
