# Bounded Context Map

> **See also:** [context-map.md](context-map.md) — integration patterns at each seam (relationships, published language, violations).

> **Phase 2 note:** Updated 2026-07-03 for the post-umbrella namespaces (`GibberingEngine.*`, `GibberingTales.*`, `GibberingTalesWeb.*`, `GibberingTalesAdmin.*`). See [engine-decomposition.md](engine-decomposition.md) for the conversion history and the pre-umbrella names.

The module structure follows the polytope bounded context decomposition from
[docs/papers/polytope-architecture.md](../papers/polytope-architecture.md). Each bounded
context owns its namespace. No context reaches directly into another's modules — all
cross-context interaction is via the command bus (C) or event bus (E). See #108 for the
EventBus port definition, #109 for the bus classification audit, and
[docs/architecture/context-map.md](context-map.md) for the full context map (seams, patterns, violations).

## Scene *(Behavioral dimension — core game authority)*

```
GibberingTalesWeb.Engine.SceneServer  ← single-writer authoritative process (1 GenServer per session)
GibberingTalesWeb.Engine.State        ← immutable state struct (tiles, entities, selection, turn order)
GibberingTalesWeb.Engine.Rules        ← pure functions: movement, targeting, combat
GibberingTales.Engine.GameSession  ← session supervisor / registry entry
GibberingEngine.SpriteCompositor ← sprite composition pipeline
```

Namespace: `GibberingTalesWeb.Engine.*` for the runtime triad (State, Rules, SceneServer),
with the session registry in `GibberingTales.Engine.*` (maps to the Scene bounded context
in polytope terms; extracting a dedicated `Scene` namespace out of the web app is a
future refactor tracked separately if desired).

## Rules Engine *(Structural dimension — core domain)*

```
GibberingEngine.Ruleset                        ← behaviour port: any ruleset must implement this
GibberingEngine.RuleModifier            ← generic modifier struct: source, operation, value (engine layer)
GibberingTales.Rulesets.DnD5e                 ← D&D 5e SRD ruleset (Strategy implementation)
GibberingTales.Rulesets.DnD5e.Stats           ← HP, speed, proficiency, stat modifiers
GibberingTales.Rulesets.DnD5e.Spell           ← spell resolution, damage, saving throws
GibberingTales.Rulesets.DnD5e.ModifierPipeline ← Chain of Responsibility over modifiers
GibberingTales.Rulesets.DnD5e.Predicate       ← composable boolean rule conditions
GibberingTales.Rulesets.DnD5e.Condition       ← condition type definitions (Paralyzed, Frightened …)
```

## Content Catalogue *(Structural dimension — core domain)*

```
GibberingTales.Catalogue           ← context boundary / public API
GibberingTales.Catalogue.Race      ← race definitions with stat bonuses and traits
GibberingTales.Catalogue.Class     ← class definitions with features and base stats
GibberingTales.Catalogue.Spell     ← spell definitions: damage, range, school
GibberingTales.Catalogue.Monster   ← monster stat blocks (SRD-legal subset)
GibberingTales.Catalogue.Appearance ← visual metadata for catalogue entries
GibberingTales.Catalogue.Style     ← display style declarations
GibberingTales.Catalogue.Cache     ← in-process ETS cache over the DB
```

Legacy in-memory reference modules (`GibberingTales.Data.Races`, `GibberingTales.Data.Classes`,
`GibberingTales.Data.Spells`, `GibberingTales.Data.Monsters`, `GibberingTales.Data.Items`,
`GibberingTales.Data.Backgrounds`) are internal helpers within the Content Catalogue context;
they pre-date the DB-backed `Catalogue.*` layer and will be migrated or removed over time.

## Campaign Lifecycle *(Structural dimension — supporting domain)*

```
GibberingTales.Campaigns           ← context boundary / public API
GibberingTales.Campaign            ← Ecto schema: campaign record
GibberingTales.CampaignCharacter   ← Ecto schema: character-in-campaign join
GibberingTales.CampaignCharacters  ← context operations over CampaignCharacter
GibberingTales.CampaignMember      ← Ecto schema: player membership
GibberingTales.CampaignInvitation  ← Ecto schema: invitation record
GibberingTales.CampaignInvitations ← context operations over invitations
GibberingTales.CampaignInviteLink  ← Ecto schema: shareable invite link
GibberingTales.CampaignInviteLinks ← context operations over invite links
GibberingTales.Character           ← Ecto schema: character sheet
GibberingTales.Characters          ← context operations over characters
```

## Identity and Authorization *(Structural dimension — supporting domain)*

```
GibberingTales.Accounts            ← context boundary / public API (users, sessions, auth)
GibberingTales.Accounts.User       ← Ecto schema: player account
GibberingTalesAdmin.Admin               ← admin surface of this context (support users, audit)
GibberingTalesAdmin.Admin.SupportUser   ← Ecto schema: admin credential
GibberingTalesAdmin.Admin.AuditLog      ← Ecto schema: admin action log
```

## Observability *(Structural dimension — generic domain)*

```
GibberingEngine.Monitoring.MetricsStore         ← behaviour port: metric storage backend
GibberingTalesWeb.Monitoring.Stores.Local         ← ETS-backed adapter (production)
GibberingEngine.Monitoring.Stores.NoOp          ← no-op adapter (test)
GibberingTales.Monitoring.CampaignMetricSnapshot ← snapshot schema
```

## Notification *(Structural dimension — generic domain)*

Namespace: `GibberingTales.Notification` (assigned; no module exists yet). Currently
implemented as direct `Phoenix.PubSub` calls scattered across contexts. A thin
wrapper module encapsulating those calls is the planned scope, once the EventBus port
(#108) and bus classification audit (#109) are complete.

## Bus *(Integration dimension — meta-hexagon)*

```
GibberingEngine.EventBus              ← behaviour port: broadcast/2, broadcast_batch/2, subscribe/1, unsubscribe/1
GibberingTalesWeb.EventBus.PubSub       ← adapter: Phoenix.PubSub (production + integration tests)
GibberingEngine.EventBus.Local        ← adapter: in-memory ETS GenServer (unit tests, no PubSub process)
```

All cross-context event broadcasts and subscriptions go through `GibberingEngine.EventBus`. No bounded
context calls `Phoenix.PubSub` directly. The active adapter is selected via application config:

    config :gibbering, GibberingEngine.EventBus, adapter: GibberingTalesWeb.EventBus.PubSub

Swapping adapters requires no change to any bounded context module. See §3.3, §10.3 of the
polytope paper for the port/adapter rationale.

## Web Adapter *(Presentational dimension)*

```
GibberingTalesWeb.Router             ← /  →  /lobby/:id  →  /game/:id
GibberingTalesWeb.GameLive           ← game board LiveView: event handler + SVG + sprites
GibberingTalesWeb.LobbyLive          ← party setup LiveView
GibberingTalesWeb.CampaignPrepLive   ← DM campaign preparation
GibberingTalesWeb.DashboardLive      ← player dashboard
GibberingEngine.Projection.Isometric      ← pure functions: grid→screen coordinate math (2:1 dimetric)
GibberingTalesWeb.Components.CharacterSprite ← inline SVG sprite components
```

## Data Pipeline *(Integration dimension — ingestion)*

```
GibberingTales.Pipeline.LegalGuard   ← WotC Product Identity filter
```

## Published Language Registry *(Cross-cutting — shared contract)*

The `Events` namespaces (`GibberingEngine.Events.*` for generic engine events,
`GibberingTales.Events.*` for game-specific and notification events) are the
**Published Language** for all cross-context event contracts. The registry is owned by
no single bounded context. Every event type that flows across a context boundary on
the event bus is defined here. See `docs/papers/polytope-architecture.md` §3.2.

```
GibberingEngine.Events.EventBatch       ← batch envelope: command, batch_id, correlation_id, events
GibberingEngine.Events.Upcaster         ← behaviour: upcast/2, current_version/0 (event-log migration)
GibberingEngine.Events.Decoder          ← decode(module, raw_map) — event-log read path
GibberingEngine.Events.*         ← 10 generic engine events: EntityMoved, TurnAdvanced,
                                     PhaseTransitioned, HPAdjusted, ResourceConsumed,
                                     ContainerOpened, RollRequired, SessionEnded,
                                     LogEntryRevealed, LogEntryHidden
GibberingTales.Events.DnD5e.*          ← 7 D&D 5e-specific events: AttackResolved, DamageDealt,
                                     SpellCast, ConditionApplied, ConditionRemoved,
                                     ItemEquipped, ItemTaken
GibberingTales.Events.Notification.*   ← out-of-band DM/player message structs: BroadcastSent, WhisperDelivered
```

**Versioning policy (brainstorm #16):** Each event struct declares `@current_version 1` and
implements `GibberingEngine.Events.Upcaster`. Fields are never renamed or removed once published
(additive-only discipline). Breaking changes produce a new event type. Version checking lives
exclusively in the `Decoder` at the event-log boundary; in-process events are live typed structs.

**Consumer-driven contract testing:** In-process events are compile-time contracts — struct
pattern matching in `handle_info/2` is a compile-time guarantee; shape mismatches are compiler
errors. Formal consumer-driven contract (CDC) testing (e.g. Pact-style per-consumer contract
files) is deferred until the persistent event log and a multi-process consumer topology are
introduced. At that point, the `ContractRegistry` described in the polytope treatise §15.2 is
the appropriate home. Until then, the `GibberingEngine.Events.Decoder` + `Upcaster` chain is the
sole contract enforcement boundary that must be covered by tests.

**Event Storming output:** Brainstorm #15 is the canonical Event Storming record for the scene
context — it lists the domain events, their single producer (SceneServer), and known consumers
(GameLive, admin). The event bus classification table and the Event Cascade Batch Emission
section above are the living architecture artefacts derived from that record.
