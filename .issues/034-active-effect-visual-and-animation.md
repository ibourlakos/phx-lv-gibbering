# #34 · Active effect visual representation and animation

**Status:** open
**Opened:** 2026-06-05
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

**Acceptance criteria**
- [ ] Static visual representation approach decided (metadata on struct vs rendering declaration)
- [ ] Animation trigger model decided (data-driven clips vs component-per-event)
- [ ] Cascade sequencing for animations designed (how the UI serialises a chain of events)
- [ ] Sustain animation lifecycle in LiveView documented (start/stop tied to effect presence in registry)