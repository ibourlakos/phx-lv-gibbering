# #132 · Scene entity appearance catalogue and dev seed coverage

**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-20
**Priority:** medium
**Tags:** gameplay, rendering, architecture

The dev seed data is ad-hoc and sparse on visual variety. There is no curated preset
catalogue of common scene entities (creatures, containers, scenery) with correct
appearance records, and no guarantee that seed data exercises the one-to-many
entity→appearance relationship.

Three related gaps:

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

**3. Entity state vocabulary**
The appearance system maps condition states to appearance records, but there is no canonical definition of what states an entity can be in. Before appearance records can be authored correctly, the state space must be documented as a vocabulary reference (similar to `docs/architecture/predicate-vocabulary.md`).

State categories to define:
- **Vitality states** (HP-driven): alive, bloodied (<50% HP), dying, unconscious, dead; destroyed for objects
- **D&D 5e conditions** (15 official): blinded, charmed, deafened, exhausted, frightened, grappled, incapacitated, invisible, paralyzed, petrified, poisoned, prone, restrained, stunned, unconscious
- **Game-system states** (engine-specific): concentrating, raging, hidden (stealth), action economy markers (action/bonus/reaction spent)
- **Object states**: intact, damaged, destroyed, open/closed, locked/unlocked, trapped/disarmed

Each state entry should declare its visual impact tier:
- **Tier 1** — requires a separate appearance record (prone, dead, petrified, invisible, destroyed, open/closed)
- **Tier 2** — rendered as an SVG badge/overlay on the existing sprite (poisoned, stunned, grappled, concentrating, etc.) — see `docs/architecture/features/active-effects.md` for the badge system
- **Tier 3** — panel information only, no map visual (deafened, surprised, exhaustion level)

Source: brainstorm #18, Q9 discussion.

**4. Catalogue schema fields: description and object_subtype**
Catalogue entries (not entity instances) are the right home for:
- `description` / flavour text — shown in the inspection panel when a player clicks an
  object or decoration. Instances inherit the catalogue description; a per-instance
  override is optional.
- `object_subtype` — currently stored as `stats["object_subtype"]` on entity instances
  (a freeform map key). This should be a validated field on the catalogue entry
  (`static_decor | loot_source`), with instances deriving it from their catalogue
  reference. The `stats` map workaround is a known technical debt to retire.

Source: brainstorm #18, Q5 decision.

**Acceptance criteria**
- [x] `docs/architecture/entity-states.md` is created, covering all four state categories with visual impact tier per entry
- [x] A preset catalogue module (or seed fixture) defines at minimum: goblin (humanoid creature), chest (loot_source object), dead_tree and rock (static_decor objects)
- [x] Each preset has ≥1 appearance record linked to a valid sprite key
- [x] At least one preset has ≥2 appearance records (demonstrating the one-to-many relation)
- [x] Dev seeds use these presets; `mix ecto.setup` produces a scene with visual variety covering all entity types (hero, creature, loot_source, static_decor)
- [x] Appearance records survive a `mix ecto.reset` without manual intervention
- [x] Catalogue entries carry a `description` field (flavour text); at minimum the four presets above have non-empty descriptions
- [x] `object_subtype` is a validated field on the catalogue entry schema; `stats["object_subtype"]` workaround is removed from entity instances and seeds

**Implementation notes**
- New `entity_presets` table (`Gibbering.Catalogue.EntityPreset`): key, name, entity_type, object_subtype (validated: static_decor | loot_source), description.
- `appearances` table gained a `state` field (string, default "default"); unique constraint updated to `(style_id, content_type, content_key, state)`. Appearances map is now keyed by `{type, key, state}` 3-tuples.
- Goblin has two appearance records (state="default" + state="dead") demonstrating the one-to-many.
- `Entity` schema gained `preset_key` (nullable string). `stats["object_subtype"]` workaround removed from seeds; `object_subtype` now derived at scene load from the preset.
- `State.from_campaign/2` and `reload_entities` accept an optional presets map and populate `:object_subtype` and `:description` on each engine entity from its preset (falling back to `stats["object_subtype"]` for entities without a preset key).
- `Rulesets.DnD5e.Inventory.object_subtype/1` now reads `entity[:object_subtype]` (atom key) instead of `stats["object_subtype"]`.
- `appearances_for_style/1` returns `%{{type, key, state} => data}` 3-tuple keys; all callers updated.
