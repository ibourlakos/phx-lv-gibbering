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