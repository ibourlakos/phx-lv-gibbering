# Brainstorm #32 — GibberingDuels concept game

**Status:** open

## Context

The engine decomposition plan ([`docs/architecture/engine-decomposition.md`](../architecture/engine-decomposition.md)) calls for a toy game — `GibberingDuels` — to concept-prove that the extracted `gibbering_engine` app can host a second game without importing anything from `gibbering_dnd5e`. If it can, the decomposition boundary is clean. If it can't, the boundary needs work before committing to the umbrella structure.

This brainstorm designs that minimal concept game.

## Concept: 2-player card-placement on a 5×5 grid

- **Players:** 2
- **Grid:** 5×5 isometric tiles rendered by the same `IsoProjection` + `SpriteCompositor` pipeline
- **Entities:** "creature cards" placed on tiles; each has HP and one attack
- **Ruleset:** `GibberingDuels.Ruleset` implementing `@behaviour GibberingEngine.Ruleset`
- **No D&D:** no spell slots, no ability modifiers, no dice (or use dice with no D&D weighting)
- **Turn:** place a new card OR move a card one tile OR attack an adjacent card
- **Attack:** attacker deals 1 damage; no dice required (simplest possible ruleset)
- **Win condition:** opponent's last card reaches 0 HP

## Events used

Only generic engine events — zero D&D events:
- `EntityMoved` — card repositioned
- `HpAdjusted` — card takes damage
- `TurnAdvanced` — round increments, player switches
- `SessionEnded` — game over

## Open questions

- [ ] Should GibberingDuels live as a standalone app in the umbrella (`apps/gibbering_duels/`) or as a separate repo?
- [ ] Does the `Ruleset` behaviour need a `place_entity` callback, or can card placement reuse existing entity placement mechanics in SceneServer?
- [ ] How does the card appearance feed into `SpriteCompositor`? Custom `Catalogue.Appearance` records with `content_type: "card"`?
- [ ] What is the minimal UI needed to prove the concept — should it reuse `GameLive` with a different ruleset wired in, or have its own LiveView?
- [ ] Is this worth building before Phase 2 (umbrella conversion), or does the umbrella need to exist first for it to be meaningful?
- [ ] Fog of war: none, or does the engine handle it generically and GibberingDuels simply opts out?

## Decisions

*(to be filled as questions settle)*

## Issues to open

*(to be filled after settling)*
