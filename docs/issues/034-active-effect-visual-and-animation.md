# #34 · Active effect visual representation and animation

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-11
**Priority:** medium
**Tags:** discovery, rendering, gameplay

Active effects — conditions, buffs, debuffs, area spells, activated ability states — need both a static visual representation on the map and animated transitions when they are applied, sustained, or removed. This touches the SVG rendering pipeline, the scene-level effects registry, and the event log.

## Two distinct problems

### A. Static visual representation

Every `ActiveEffect` in the scene registry needs rendering metadata describing how it appears:

- **Entity-targeted effects** (Paralyzed, Blessed, Raging): icon or colour indicator on the affected entity's tile. Possibly an overlay sprite or a coloured ring.
- **Area effects** (Fog of Cloud, Wall of Fire, Darkness): a geometry overlay on the map — shape (sphere, cone, cube, line), radius or length in tiles, fill colour and opacity, border style.
- **Effect-entities** (Spiritual Weapon, Flaming Sphere): full entity representation with position and turn order slot, but derived entirely from the spell and caster stats — not a character sheet.

Design questions: is the visual metadata part of the `ActiveEffect` struct itself, or is it in a separate rendering declaration looked up by effect key? The latter is cleaner (separates data from presentation) but requires the renderer to know about all effect keys.

### B. Animation

When an effect is applied or removed, the transition should be animated:

- **Application**: a flash, a swirl, an icon flying in — depends on effect type (fire spell vs a disease condition vs a divine buff feel different).
- **Sustain**: some effects pulse or glow while active (Concentration spells, Rage).
- **Removal**: effects fade out, shatter, or dissipate depending on how they ended (expired naturally vs dispelled vs concentration broken vs saved against).

The event log is the natural driver for animations: the LiveView subscribes to scene events, and each event type maps to an animation sequence. The animation layer should not know about game state — it only knows about event types and their visual signatures.

Design questions:
- Are animations data-driven (each effect key maps to a named animation clip) or code-driven (each event type triggers a component with custom SVG/CSS animation)?
- How does the UI know an animation is complete before rendering the next event? (Especially important for cascade chains — attack roll → hit → damage → condition applied.)
- Concentration sustain animations need to be tied to the effect's lifetime, not a single event. How is a looping/pulsing animation started and stopped cleanly in LiveView?

## Relation to other issues

- Depends on the scene-level effects registry design (#30)
- The event log as the animation driver is an argument for it being part of `Engine.State` from day one (#12)
- Effect-entities overlap with multi-tile entity footprints (#28)
- Rendering metadata may interact with the isometric depth ordering (#13)

## Design Decisions

### 1. Static visual representation — rendering declaration in the Ruleset

**Decision:** rendering metadata lives in a new Ruleset callback `effect_visual/1`, not in the `ActiveEffect` struct. The engine struct stays pure data; the SVG pipeline queries `state.ruleset.effect_visual(condition_id)` at render time.

`effect_visual/1` returns a tagged tuple:

```elixir
@callback effect_visual(condition_id :: atom()) ::
    {:entity_badge, color: String.t(), icon: atom()}
  | {:area_overlay, shape: :sphere | :cone | :cube | :line, radius: number(), fill: String.t()}
  | {:effect_entity, sprite: String.t()}
  | :none
```

The layer stack gains two new entries:
- **Layer 2b** (between decorations and move overlay): area effect overlays — `<g>` shapes driven by `{:area_overlay, …}` returns.
- **Layer 4b** (above entity sprite, below selection ring): entity condition badges — small coloured circles or icons per active condition, driven by `{:entity_badge, …}` returns.

Effect-entities (`{:effect_entity, …}`) are injected into the entity depth-sort list as a virtual entity; they share the existing Layer 4 rendering path.

Rationale: mirrors the existing `action_buttons/2` pattern — the Ruleset returns pure data structs; the renderer consumes them. The engine has no knowledge of presentation.

### 2. Animation trigger model — data-driven clips via JS hook

**Decision:** data-driven animation clips delivered via a new `EffectAnimation` JS hook on `#game-board`, following the `DiceRoll` hook precedent.

When a scene event requires a visual animation, the LiveView pushes a `play_effect_animation` event:

```elixir
push_event(socket, "play_effect_animation", %{
  type: "condition_applied",   # or "condition_removed", "damage_taken", "spell_cast", …
  condition: "poisoned",
  target_id: entity_id,
  duration_ms: 800
})
```

The hook maps `type` → a CSS class applied to the target SVG `<g>` element for `duration_ms`, then removes it. The mapping is a static manifest in `app.js` — no server roundtrip needed.

Rationale: server-authoritative. No client game logic. Consistent with the existing dice animation architecture.

### 3. Cascade sequencing — server-side queue with `Process.send_after`

**Decision:** the LiveView serialises animation chains entirely on the server using a `pending_animations` list in socket assigns and `Process.send_after`.

When a scene action produces multiple ordered events (e.g. attack → hit → damage → Poisoned applied), the `SceneServer` publishes them as `{:scene_events, [%{…}, …]}`. The LiveView:

1. Prepends them to `assigns.pending_animations`.
2. Pops and plays the head immediately via `push_event/3`.
3. Schedules `Process.send_after(self(), :advance_animation_queue, head.duration_ms)`.
4. On `handle_info(:advance_animation_queue, socket)`: pops next, repeats.

No client ACK required. Duration is declared in the animation manifest (same map the hook uses). Deterministic sequencing with no client-server synchronisation overhead.

### 4. Sustain animation lifecycle — CSS keyframe class toggling

**Decision:** looping / pulsing sustain animations are CSS `@keyframes` tied entirely to class presence on a rendered SVG element. No explicit start/stop signals.

Each entity `<g>` in Layer 4 contains a child `<g class="effect-overlays">`. The renderer adds CSS classes corresponding to active conditions (e.g. `"anim-pulse-concentration"`, `"anim-pulse-rage"`). LiveView diffs remove the class when the condition is cleared from `entity.conditions`. The browser starts/stops the animation automatically — the animation lifetime is the element's class lifetime.

Class-to-animation mapping is in the project CSS; it does not touch JS. Adding a new sustain animation requires only a new CSS rule and a new `{:entity_badge, …}` visual declaration in the Ruleset.

**Acceptance criteria**
- [x] Static visual representation approach decided (metadata on struct vs rendering declaration)
- [x] Animation trigger model decided (data-driven clips via JS hook)
- [x] Cascade sequencing for animations designed (server-side queue with `Process.send_after`)
- [x] Sustain animation lifecycle in LiveView documented (CSS keyframe class tied to `entity.conditions` presence)