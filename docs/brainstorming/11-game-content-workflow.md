I want to define what changes will be required when upserting game content.

Potential game content (there may be more types):
 - races
 - classes, subclasses, character backgrounds
 - spells and active effects
 - abilities
 - items (weapons, consumables, armor, clothing, etc)
 - static maps (sizes, look and feel etc)
 - static map decorations (rocks, buildings, trees, etc)
 - interactive map content (boxes, doors, etc)
 - monsters
 - notable individuals (similar to monsters essentially but not necessarily evil or opponents)
 - event visual effects
 - maybe more events?
 - appearance components

Change span:
 - data model and records
 - seed and testing data
 - derived data
 - appearance visuals
 - player/dm interface (e.g. new abilities should be added with their theme and whatnot)
 - rendering requirements
 - testing routines
 - maybe web frontend changes?
 - game/scene state or other equivalent changes


The goal is to have a definitive list of game content types and map a workflow on how to upsert them in this system.
These would also affect what the players have available in the game app and what the support users can work with or how they can adjust content in any existing content editing tools.

As a natural follow up I would like to
 - add at least the races that appear in BG3
 - all the standard classes
 - an initial assortment of monsters (care for legal)
 - an initial assortment of various items (care for legal issues)
 - enrich the choices at character creation/appearance

---

## Issues Opened
_Triaged 2026-06-06_

| # | Title | Open questions handled |
|---|---|---|
| [#88](../issues/088-game-content-type-taxonomy.md) | Game content type taxonomy and upsert workflow | Definitive content type list; change surface per type; multi-style appearance slot definition |
| [#89](../issues/089-initial-game-content-population.md) | Initial content population — races, classes, starter monsters/items | BG3 races, standard classes, starter monsters/items; character creation enrichment |

Remaining open questions (e.g. whether characters are campaign-scoped or portable, exact appearance component schema) are tracked in #88 and #89, and depend on decisions in brainstorm #14 → issue [#98](../issues/098-dst-art-direction-spec.md) (art direction spec) and [#99](../issues/099-multi-style-appearance-system.md) (multi-style appearance system).