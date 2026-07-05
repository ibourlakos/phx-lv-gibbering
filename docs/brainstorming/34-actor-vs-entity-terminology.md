# Brainstorm #34 — Actor vs Entity: scene runtime terminology

**Status:** open
**Date:** 2026-07-01

---

## The problem

The codebase currently uses "entity" for two different things:

1. The Ecto schema and DB row — a persistent domain object with an identity that survives between sessions (`Gibbering.Entity`, `create_entities` migration)
2. The in-memory runtime thing living in `Engine.State.entities` — a map of scene participants that exist only while a session is live

These are different concepts at different layers. The conflation makes the engine/tales boundary harder to see and reason about.

---

## Proposed terminology

### Actor (engine concept)

Borrowed from Unreal Engine: "any object that can be placed or spawned in the world."

An **Actor** is a runtime scene participant:
- Lives in `Engine.State` (currently `entities` field → rename to `actors`)
- Has a position, visual appearance, current in-session state
- Ephemeral — exists only while a session is live
- Pure engine concept: `%GibberingEngine.Actor{}` struct, no Ecto, no DB awareness
- The engine works exclusively with Actors; it has no knowledge of how they were constructed

### Entity (tales concept)

An **Entity** is a persistent domain object:
- Has an Ecto schema and a DB row in `gibbering_tales`
- Has an identity (`id`) that survives between sessions
- Carries the canonical record: stats, name, appearance key, campaign assignment, etc.
- The game layer (Tales) loads Entities from DB and constructs Actors from them when a session starts
- When the session ends (or snapshots), any mutable in-session state is written back to the Entity record

### The relationship

```
DB (Entity)  →  session start  →  Actor (in Engine.State)  →  session end  →  DB snapshot
```

Tales is responsible for the translation in both directions. The engine never sees the Entity; it only ever holds Actors.

---

## Implications

### Field rename in Engine.State

`Engine.State.entities` → `Engine.State.actors`

This is a significant rename cascade (SceneServer, Rules, all call sites). Belongs in Phase 2b (#169) as part of the engine extraction, since the module is being moved and renamed anyway.

### Ecto schema naming

The `Gibbering.Entity` Ecto schema stays named `Entity` in `gibbering_tales` — it is a correct name for the DB-level concept. The DB table `entities` also stays. There's no rename needed at the tales layer.

### AppearanceArchetype → ActorAppearance

`AppearanceArchetype` was named for D&D-flavoured sprite archetypes. Reframed as the engine's model for how any Actor looks: composable visual layers, game-agnostic. Rename to `ActorAppearance` (or `ActorVisual`) during Phase 2b.

### Engine concerns update

With Actor as the explicit term, the engine's six concerns are:

1. **Game loop** — session lifecycle, turn/phase machine, `Ruleset` behaviour (the seam)
2. **Event pipeline** — `EventBus`, `EventBatch`, `Upcaster`, generic event structs
3. **Actor appearance** — composable layer model for any scene Actor (`ActorAppearance`, `SpriteCompositor`)
4. **Projection** — `Projection` behaviour + implementations (`Isometric`, `TopDown`); grid↔screen coordinate math. `IsoProjection` is renamed `Projection.Isometric` and becomes the first implementation. Tracked by #123.
5. **HUD** — pure data structs the ruleset populates after each state change; the web layer renders them without game-specific knowledge (action bar, overlays, prompts, status indicators). Replaces `ConditionBadge`, which moves to Tales as a D&D-specific appearance record.
6. **Observability** — `Monitoring` port + adapters

`ConditionBadge` is removed from the engine entirely — badges are a D&D UI convention, not a generic engine primitive. The actor appearance layer system (concern #3) handles any overlay a game wants to show; the ruleset supplies the content.

"HUD" is the confirmed term for concern #5 — borrowed from UE/Godot, unambiguous in context.

---

## OTP naming caveat

"Actor" already has meaning in Erlang/Elixir: every OTP process implements the actor model. There is potential confusion between an OTP actor (a process) and a scene actor (a data struct). In practice the distinction is clear — one is a process, the other is `%GibberingEngine.Actor{}` — but it is worth being explicit in documentation. If this causes real friction during development, the Unreal alternative **Pawn** (an Actor that can be possessed/controlled) is available, though Actor is more general and covers non-controllable scene objects (obstacles, containers, etc.).

---

## Open questions

- Does an Actor carry a reference back to its Entity `id` (for Tales to snapshot), or is that a Tales-layer concern (a separate mapping outside the engine)?
- Is an obstacle or a container a first-class Actor, or does the engine have sub-types (Pawn for controllable, Prop for static)?
- What is the minimal `%GibberingEngine.Actor{}` struct? Position, appearance key, and what else?
