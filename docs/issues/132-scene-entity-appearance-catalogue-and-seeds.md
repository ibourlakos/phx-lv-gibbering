# #132 · Scene entity appearance catalogue and dev seed coverage

**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** gameplay, rendering, architecture

The dev seed data is ad-hoc and sparse on visual variety. There is no curated preset
catalogue of common scene entities (creatures, containers, scenery) with correct
appearance records, and no guarantee that seed data exercises the one-to-many
entity→appearance relationship.

Two related gaps:

**1. Preset appearance catalogue**
A canonical list of entity presets — at minimum: a humanoid creature (goblin), a loot
container (chest), and common scenery (dead tree, rock/boulder, pillar) — each with
at least one appearance record wired to a real sprite key. This drives both seed data
and the scene entity picker in the DM UI.

**2. One-to-many entity → appearances**
An entity instance can have multiple appearance records (style variants, equipment
states, condition states — e.g. a goblin with a sword vs. unarmed; a chest open vs.
closed). The seed data must exercise this relationship with at least one multi-appearance
entity so the compositing pipeline is covered end-to-end. See issues #99, #53, #100
for the appearance system design.

**Acceptance criteria**
- [ ] A preset catalogue module (or seed fixture) defines at minimum: goblin (humanoid creature), chest (loot_source object), dead_tree and rock (static_decor objects)
- [ ] Each preset has ≥1 appearance record linked to a valid sprite key
- [ ] At least one preset has ≥2 appearance records (demonstrating the one-to-many relation)
- [ ] Dev seeds use these presets; `mix ecto.setup` produces a scene with visual variety covering all entity types (hero, creature, loot_source, static_decor)
- [ ] Appearance records survive a `mix ecto.reset` without manual intervention
