# Bounded Context Map

> **See also:** [context-map.md](context-map.md) — integration patterns at each seam (relationships, published language, violations).

The module structure follows the polytope bounded context decomposition from
[docs/papers/polytope-architecture.md](../papers/polytope-architecture.md). Each bounded
context owns its namespace. No context reaches directly into another's modules — all
cross-context interaction is via the command bus (C) or event bus (E). See #108 for the
EventBus port definition, #109 for the bus classification audit, and
[docs/architecture/context-map.md](context-map.md) for the full context map (seams, patterns, violations).

## Scene *(Behavioral dimension — core game authority)*

```
Gibbering.Engine.SceneServer  ← single-writer authoritative process (1 GenServer per session)
Gibbering.Engine.State        ← immutable state struct (tiles, entities, selection, turn order)
Gibbering.Engine.Rules        ← pure functions: movement, targeting, combat
Gibbering.Engine.GameSession  ← session supervisor / registry entry
Gibbering.Engine.SpriteCompositor ← sprite composition pipeline
```

Namespace: `Gibbering.Engine.*` (maps to the Scene bounded context in polytope terms;
rename to `Gibbering.Scene.*` is a future refactor tracked separately if desired).

## Rules Engine *(Structural dimension — core domain)*

```
Gibbering.Ruleset                        ← behaviour port: any ruleset must implement this
Gibbering.Engine.RuleModifier            ← generic modifier struct: source, operation, value (engine layer)
Gibbering.Rulesets.DnD5e                 ← D&D 5e SRD ruleset (Strategy implementation)
Gibbering.Rulesets.DnD5e.Stats           ← HP, speed, proficiency, stat modifiers
Gibbering.Rulesets.DnD5e.Spell           ← spell resolution, damage, saving throws
Gibbering.Rulesets.DnD5e.ModifierPipeline ← Chain of Responsibility over modifiers
Gibbering.Rulesets.DnD5e.Predicate       ← composable boolean rule conditions
Gibbering.Rulesets.DnD5e.Condition       ← condition type definitions (Paralyzed, Frightened …)
```

## Content Catalogue *(Structural dimension — core domain)*

```
Gibbering.Catalogue           ← context boundary / public API
Gibbering.Catalogue.Race      ← race definitions with stat bonuses and traits
Gibbering.Catalogue.Class     ← class definitions with features and base stats
Gibbering.Catalogue.Spell     ← spell definitions: damage, range, school
Gibbering.Catalogue.Monster   ← monster stat blocks (SRD-legal subset)
Gibbering.Catalogue.Appearance ← visual metadata for catalogue entries
Gibbering.Catalogue.Style     ← display style declarations
Gibbering.Catalogue.Cache     ← in-process ETS cache over the DB
```

Legacy in-memory reference modules (`Gibbering.Data.Races`, `Gibbering.Data.Classes`,
`Gibbering.Data.Spells`, `Gibbering.Data.Monsters`, `Gibbering.Data.Items`,
`Gibbering.Data.Backgrounds`) are internal helpers within the Content Catalogue context;
they pre-date the DB-backed `Catalogue.*` layer and will be migrated or removed over time.

## Campaign Lifecycle *(Structural dimension — supporting domain)*

```
Gibbering.Campaigns           ← context boundary / public API
Gibbering.Campaign            ← Ecto schema: campaign record
Gibbering.CampaignCharacter   ← Ecto schema: character-in-campaign join
Gibbering.CampaignCharacters  ← context operations over CampaignCharacter
Gibbering.CampaignMember      ← Ecto schema: player membership
Gibbering.CampaignInvitation  ← Ecto schema: invitation record
Gibbering.CampaignInvitations ← context operations over invitations
Gibbering.CampaignInviteLink  ← Ecto schema: shareable invite link
Gibbering.CampaignInviteLinks ← context operations over invite links
Gibbering.Character           ← Ecto schema: character sheet
Gibbering.Characters          ← context operations over characters
```

## Identity and Authorization *(Structural dimension — supporting domain)*

```
Gibbering.Accounts            ← context boundary / public API (users, sessions, auth)
Gibbering.Accounts.User       ← Ecto schema: player account
Gibbering.Admin               ← admin surface of this context (support users, audit)
Gibbering.Admin.SupportUser   ← Ecto schema: admin credential
Gibbering.Admin.AuditLog      ← Ecto schema: admin action log
```

## Observability *(Structural dimension — generic domain)*

```
Gibbering.Monitoring.MetricsStore         ← behaviour port: metric storage backend
Gibbering.Monitoring.Stores.Local         ← ETS-backed adapter (production)
Gibbering.Monitoring.Stores.NoOp          ← no-op adapter (test)
Gibbering.Monitoring.CampaignMetricSnapshot ← snapshot schema
```

## Notification *(Structural dimension — generic domain)*

Namespace: `Gibbering.Notification` (assigned; no module exists yet). Currently
implemented as direct `Phoenix.PubSub` calls scattered across contexts. A thin
wrapper module encapsulating those calls is the planned scope, once the EventBus port
(#108) and bus classification audit (#109) are complete.

## Bus *(Integration dimension — meta-hexagon)*

```
Gibbering.EventBus              ← behaviour port: broadcast/2, broadcast_batch/2, subscribe/1, unsubscribe/1
Gibbering.EventBus.PubSub       ← adapter: Phoenix.PubSub (production + integration tests)
Gibbering.EventBus.Local        ← adapter: in-memory ETS GenServer (unit tests, no PubSub process)
```

All cross-context event broadcasts and subscriptions go through `Gibbering.EventBus`. No bounded
context calls `Phoenix.PubSub` directly. The active adapter is selected via application config:

    config :gibbering, Gibbering.EventBus, adapter: Gibbering.EventBus.PubSub

Swapping adapters requires no change to any bounded context module. See §3.3, §10.3 of the
polytope paper for the port/adapter rationale.

## Web Adapter *(Presentational dimension)*

```
GibberingWeb.Router             ← /  →  /lobby/:id  →  /game/:id
GibberingWeb.GameLive           ← game board LiveView: event handler + SVG + sprites
GibberingWeb.LobbyLive          ← party setup LiveView
GibberingWeb.CampaignPrepLive   ← DM campaign preparation
GibberingWeb.DashboardLive      ← player dashboard
GibberingWeb.IsoProjection      ← pure functions: grid→screen coordinate math (2:1 dimetric)
GibberingWeb.Components.CharacterSprite ← inline SVG sprite components
```

## Data Pipeline *(Integration dimension — ingestion)*

```
Gibbering.Pipeline.LegalGuard   ← WotC Product Identity filter
```

## Published Language Registry *(Cross-cutting — shared contract)*

`Gibbering.Events.*` is the **Published Language** for all cross-context event contracts.
It is owned by no single bounded context. Every event type that flows across a context
boundary on the event bus is defined here. See `docs/papers/polytope-architecture.md` §3.2.

```
Gibbering.Events                  ← registry root / namespace documentation
Gibbering.Events.EventBatch       ← batch envelope: command, batch_id, correlation_id, events
Gibbering.Events.Upcaster         ← behaviour: upcast/2, current_version/0 (event-log migration)
Gibbering.Events.Decoder          ← decode(module, raw_map) — event-log read path
Gibbering.Events.Engine.*         ← 10 generic engine events: EntityMoved, TurnAdvanced,
                                     PhaseTransitioned, HPAdjusted, ResourceConsumed,
                                     ContainerOpened, RollRequired, SessionEnded,
                                     LogEntryRevealed, LogEntryHidden
Gibbering.Events.DnD5e.*          ← 7 D&D 5e-specific events: AttackResolved, DamageDealt,
                                     SpellCast, ConditionApplied, ConditionRemoved,
                                     ItemEquipped, ItemTaken
Gibbering.Events.Notification.*   ← out-of-band DM/player message structs: BroadcastSent, WhisperDelivered
```

**Versioning policy (brainstorm #16):** Each event struct declares `@current_version 1` and
implements `Gibbering.Events.Upcaster`. Fields are never renamed or removed once published
(additive-only discipline). Breaking changes produce a new event type. Version checking lives
exclusively in the `Decoder` at the event-log boundary; in-process events are live typed structs.

**Consumer-driven contract testing:** In-process events are compile-time contracts — struct
pattern matching in `handle_info/2` is a compile-time guarantee; shape mismatches are compiler
errors. Formal consumer-driven contract (CDC) testing (e.g. Pact-style per-consumer contract
files) is deferred until the persistent event log and a multi-process consumer topology are
introduced. At that point, the `ContractRegistry` described in the polytope treatise §15.2 is
the appropriate home. Until then, the `Gibbering.Events.Decoder` + `Upcaster` chain is the
sole contract enforcement boundary that must be covered by tests.

**Event Storming output:** Brainstorm #15 is the canonical Event Storming record for the scene
context — it lists the domain events, their single producer (SceneServer), and known consumers
(GameLive, admin). The event bus classification table and the Event Cascade Batch Emission
section above are the living architecture artefacts derived from that record.
