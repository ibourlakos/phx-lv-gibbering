# Architecture

## Overview

The Gibbering Engine is a deliberate architectural aberration: a 2D tactical game that runs entirely server-side, streaming SVG diffs to the browser over a LiveView WebSocket. No client-side game framework. No manual WebSocket code. The server is the game.

---

## System Architecture

| Document | Contents |
|---|---|
| [Data Model](architecture/data-model.md) | DB schema, runtime State struct, static reference data |
| [Context Map](architecture/context-map.md) | All bounded contexts, seams, integration patterns, violations |
| [Bounded Contexts](architecture/bounded-contexts.md) | Module map per bounded context, Published Language registry |
| [Ruleset Behaviour](architecture/ruleset-behaviour.md) | The Ruleset port: callbacks, behaviour vs protocol, stats-as-map |
| [Multiplayer](architecture/multiplayer.md) | How PubSub + LiveView delivers multiplayer with no custom WebSocket code |
| [Data Pipeline](architecture/data-pipeline.md) | Ingestion: LegalGuard → parser → DB |
| [Event System](architecture/event-system.md) | Compound bus (C/E) classification, Single-Writer Contract |
| [Event Cascade](architecture/event-cascade.md) | Batch emission pattern, envelope fields, causation chain, state_snapshot |
| [CQRS Read Model](architecture/cqrs-read-model.md) | Projections, boundary statement, migration path, Memento strategy |
| [Predicate Vocabulary](architecture/predicate-vocabulary.md) | Closed predicate set for `RuleModifier` evaluation (8 groups, 51 predicates) |

## Feature Design Decisions

Feature-specific design decisions with bounded-context implications.

| Document | Contents |
|---|---|
| [SVG Rendering Pipeline](architecture/features/svg-rendering.md) | Isometric projection math, layer stack, sprite strategy, diff cost |
| [Active Effects](architecture/features/active-effects.md) | Badge/overlay rendering, animation triggers, cascade sequencing |
| [DM Override Events](architecture/features/dm-override-events.md) | Override taxonomy, actor field, god-mode scope |
| [Fog of War](architecture/features/fog-of-war.md) | Engine/Ruleset ownership split for LOS |
| [Party Setup Flow](architecture/features/party-setup.md) | Lobby → game flow, PubSub claim/release |
| [JS Hooks](architecture/features/js-hooks.md) | DiceRoll hook, animation push events |

## Reference Documents

Canonical domain definitions — what things are called and what states they can be in.
Architecture docs and issues link to these rather than re-defining terms inline.

| Document | Contents |
|---|---|
| [Game Content Taxonomy](reference/game-content-taxonomy.md) | Content type checklist, appearance slot registry, upsert checklist per type |

`predicate-vocabulary.md` stays in `docs/architecture/` — it is a code contract (evaluator signature + closed predicate set), not a domain glossary.

---

## Open Questions

- ~~Should `GibberingEngine.Ruleset` be a `behaviour` or a `protocol`?~~ Decided: behaviour (#14 closed)
- ~~Does fog-of-war calculation belong to the engine or the ruleset?~~ Decided: split — engine owns LOS geometry + SVG mask, ruleset owns vision_range/vision_type (#26 closed)
- How does a ruleset declare what UI action buttons to render?
- How should lobby player identity work for same-browser multi-player? (see #18)
- How should lobby edits propagate to a running `SceneServer`? (see #20)
