# #33 · Templates governance model

**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** Path [F] candidate — scope is too broad for in-issue settlement. Promote to a brainstorm when the core rules engine shape is stable enough to make governance decisions. The issue itself notes this dependency.
**Priority:** low
**Tags:** discovery, architecture

The DM (and/or the system) may allow or deny templates for entities at various points: campaign preparation, character creation, between scenes, or mid-session. Templates exist for at least: maps (scene layouts), spells (DM-customised variants of base spells), monsters (stat block overrides), and potentially class features and items.

This is a governance and permissions problem as much as a data model problem.

## What needs to be decided

**Template scope:** what can be templated? Maps, monsters, spells, and class features are obvious. Items, factions, conditions, and random table seeds are plausible. The full scope needs enumerating before a schema can be designed.

**Ownership and provenance:** a template is either system-provided (SRD defaults), DM-authored, or imported. The engine needs to distinguish these for legal reasons (only SRD-legal content in system templates) and for DM trust reasoning.

**Timing of application:** templates can be applied at: campaign creation, scene setup, character preparation (lobby), or mid-session (DM override). Each timing has different consequences for game state consistency. Mid-session application is the hardest case.

**Allow/deny mechanics:** the DM should be able to restrict which templates players can select for their characters, and possibly restrict which system templates are available for a given campaign (e.g. "no magic items in this campaign"). How is this permissions layer modelled?

**Versioning:** if a DM modifies a spell template mid-campaign, what happens to active instances of that spell already in the scene effects registry?

**Relation to the static reference layer:** the current static reference layer (Races, Classes, Spells) is immutable Elixir module data. Templates introduce a mutable, campaign-scoped overlay on top of this. The two layers must coexist clearly — the static layer is the baseline, templates are deltas.

## Notes

This will be a significant design effort. The decision has cascading effects on: the data model (where do templates live in the DB?), the UI (template browser, DM controls), and the rules engine (which layer does a spell resolution query first?). Defer until the core rules engine shape is stable.

**Acceptance criteria**
- [ ] Full list of templateable entity types decided
- [ ] Ownership and provenance model defined
- [ ] Allow/deny permission layer designed
- [ ] Template application timing rules documented (with mid-session case addressed)
- [ ] Interaction with static reference layer documented (layering / override semantics)