# The Bounded Context Polytope
## A Multidimensional Architecture Model for Complex Domain Systems

**Authors:** Ioannis (John) Bourlakos · Claude Sonnet 4.6 (Anthropic)

*Developed from the architectural design sessions of The Gibbering Engine, a turn-based D&D 5e tactical grid game built with Elixir and Phoenix LiveView. The game-specific examples throughout are illustrations of general principles applicable to any sufficiently complex software system.*

---

## Abstract

Hexagonal architecture provides a clean separation between a software domain and the infrastructure surrounding it, but it assumes a single primary concern at the center. Real systems of moderate complexity violate this assumption: they contain multiple orthogonal concerns — rules, content, lifecycle management, rendering, communication — each demanding a center of its own.

This paper introduces the *bounded context polytope*: a multidimensional generalization of hexagonal architecture in which each node of a directed graph is itself a fully encapsulated hexagon (a bounded context in the Domain-Driven Design sense), and the edges are mediated by a typed event bus rather than direct adapter pairs. The polytope resolves the O(N²) adapter-pair problem that arises when N bounded contexts must communicate, consolidates the coupling surface onto a single shared Published Language (the event schema registry), and preserves the full port-and-adapter discipline of hexagonal architecture within each node.

We develop a four-level taxonomy — dimension, parallel, context, aspect — grounded in established literature on multidimensional separation of concerns and aspect-oriented programming. We examine five dimensions the polytope exhibits: structural, temporal, behavioral, presentational, and integration. We give a semi-formal definition of the compound event bus as a hierarchical composition of transport mechanisms spanning from hardware interrupt lines to external message brokers. We address the concurrent event ordering problem inherent in multi-writer event logs and its resolution. We propose an event schema design methodology grounded in Event Storming and consumer-driven contract testing. We show that the model subsumes context-aware computing in the Dey (2001) sense, with precise mapping between context-awareness concepts and polytope primitives. Finally, we observe that the development lifecycle is itself a polytope at the meta-level, and explore the roles of human and AI actors within it.

---

## 1. Introduction

### 1.1 Motivation

Alistair Cockburn's hexagonal architecture — ports and adapters — solves a real and important problem: how do you prevent domain logic from becoming entangled with the infrastructure around it? The answer is to place the domain at the center, define abstract interfaces (ports) on its boundary, and write concrete adapters that connect those ports to the outside world. A database adapter implements a persistence port. An HTTP adapter implements a request-handling port. The domain imports nothing from adapters; adapters depend on the domain.

In many systems this is the right model. But it carries a hidden assumption: there is one primary concern at the center. The domain is a single, coherent thing.

That assumption breaks the moment a system acquires multiple genuinely orthogonal primary concerns. Consider adding a new character class — Barbarian — to a D&D game engine. The change propagates through the rules engine (rage mechanics, new action economy interactions), the content catalogue (class definition, resource tables, trait list), the campaign lifecycle (the DM can now offer this class during session preparation), the rendering layer (a rage indicator, a visual cue on rage entry), and the notification system (the combat log entry "Aldric enters a RAGE"). In a single-hexagon model, all of these land in "the domain," which is no longer a coherent single thing. Or the designer attempts to split into independent services and encounters the question hexagonal architecture was never designed to answer: how do independent domains communicate without recreating the entanglement just removed?

### 1.2 Contributions

This paper makes the following contributions:

1. **The bounded context polytope**: a named model for a directed graph of bounded contexts connected by a typed event bus, generalizing hexagonal architecture to N orthogonal concerns.
2. **A four-level taxonomy**: dimension, parallel, context, and aspect — grounded in the MDSOC and AOP literature and consistent with DDD terminology.
3. **A semi-formal bus definition**: the compound bus B = (C, E) as a hierarchical composition, distinguishing the command bus from the event bus and characterizing both within the vertical transport stack.
4. **A resolution of the concurrent event ordering problem** in hash-chained event logs under multi-writer conditions.
5. **An event schema design methodology**: a mini-cycle from Event Storming through consumer-driven contract validation and versioning policy.
6. **Absorption of context-aware computing**: a formal mapping showing that the polytope subsumes the Dey (2001) context-awareness model and extends it to a distributed setting.
7. **The meta-polytope**: the development lifecycle and its actors formalized using the same vocabulary.

### 1.3 Paper Organization

Section 2 reviews the relevant literature. Section 3 introduces the polytope and resolves the O(N²) problem. Section 4 establishes the taxonomy. Section 5 addresses time, event sourcing, and the concurrent ordering problem. Section 6 gives the semi-formal bus definition. Section 7 presents the event schema design methodology. Section 8 applies the five dimensions to a concrete system. Section 9 covers design patterns. Section 10 extends the model through the full vertical stack and deployment topology. Section 11 maps the model to context-aware computing. Section 12 treats the development lifecycle as a meta-polytope. Section 13 discusses cross-cutting themes. Section 14 states limitations and blind spots. Section 15 proposes future work. Section 16 concludes. Appendix A extends the biological analogy.

---

## 2. Background and Related Work

### 2.1 Hexagonal Architecture

Cockburn (2005) introduced hexagonal architecture (ports and adapters) as a technique for isolating application logic from its delivery mechanism. The core rule: the application core defines abstract ports; concrete adapters implement those ports; the core imports nothing from adapters. This enables the application to be driven identically by a human via a UI, a test via a test harness, or a batch script via a command line. The hexagonal shape is diagrammatic convenience, not structural constraint — the number of ports is unlimited.

The limitation, not stated by Cockburn, is that the model implies a single center. When multiple equally primary concerns coexist, the model provides no principled way to decompose them. Each concern wants to be the center, but there can only be one.

### 2.2 Domain-Driven Design

Evans (2003) introduced the bounded context as a named boundary within which a specific domain model applies and is internally consistent. The same word — "customer," "entity," "order" — may mean entirely different things in different contexts. The boundary makes the difference explicit rather than a source of silent confusion. Vernon (2013) extends this with the context map: a document of how bounded contexts relate to each other, naming the integration pattern at each seam (conformist, customer-supplier, anti-corruption layer, published language, shared kernel).

Evans's *Published Language* is the shared, explicit, versioned vocabulary by which bounded contexts exchange information across a context boundary. It is, in the polytope, the event schema registry — the most important contract in the system.

The *Anti-Corruption Layer* (ACL) (Evans, 2003) translates an external model into the internal model. Every bounded context that receives events from the bus needs a translation layer that converts the Published Language representation into its own internal domain types. The ACL is the subscriber's adapter over the event bus port.

### 2.3 Multidimensional Separation of Concerns

Tarr, Ossher, Harrison, and Sutton (ICSE 1999) argued formally that any single-axis modular decomposition forces N orthogonal concerns to coexist in each module — because the modules are organized along one axis, and the concerns vary along N axes simultaneously. They proposed multidimensional separation of concerns (MDSOC), in which each axis of variation is a *dimension* and a cross-section perpendicular to a dimension is a *hyperslice*. The polytope model uses dimension in exactly this sense and introduces *parallel* as a more geometrically intuitive synonym for hyperslice.

Kiczales et al. (ECOOP 1997) introduced aspect-oriented programming (AOP) as a technique for implementing concerns that genuinely cannot be localized to any single module — cross-cutting concerns such as security, logging, and transaction management. The polytope adopts this vocabulary: an *aspect* is a concern that cuts across multiple bounded contexts and cannot be assigned to any one of them.

### 2.4 Event-Driven Architecture and CQRS

Young (2010) articulated command-query responsibility segregation (CQRS) as the explicit separation of write operations (commands that change state and produce events) from read operations (queries over projections of past events). The command side and the event side are structurally different: a command has exactly one handler; an event has zero or more subscribers. This distinction maps directly to the polytope's two-bus architecture.

Hohpe and Woolf (2003) catalogued the canonical patterns of message-based integration: message channel, message router, event-driven consumer, publish-subscribe channel, message broker, event aggregator. The polytope's event bus instantiates many of these patterns simultaneously.

Event sourcing — treating the append-only log of domain events as the primary source of truth, with current state derived by projection — is the temporal dimension's foundational pattern. Richardson (2018) covers event sourcing, the saga pattern for distributed workflows, and consumer-driven contract testing in the context of microservice architectures.

### 2.5 Context-Aware Computing

Schilit and Theimer (1994) coined the term *context-aware* for software that adapts based on its location, nearby objects, and changes to those objects over time. Weiser (1991) had earlier articulated ubiquitous computing as the vision that computation would recede into the environment, sensed and acted upon implicitly. Dey (2001) gave the canonical formal definition: "Context is any information that can be used to characterize the situation of an entity." He identified four primary dimensions — location, identity, activity, and time — and three uses of context: presenting information differently, executing services differently, and tagging data with context metadata. Henricksen and Indulska (2004) extended context modeling to handle imperfect, conflicting, and probabilistic context.

Section 11 shows that the polytope subsumes this body of work at a higher level of abstraction.

---

## 3. The Bounded Context Polytope

### 3.1 From One Hexagon to Many

The generalization of hexagonal architecture to multiple primary concerns is to replace the single hexagon with a **directed graph of hexagons**, where each node is a bounded context with its own domain, ports, and adapters. We call this graph the **polytope** — a multidimensional generalization of the hexagon. In geometry, a polygon is two-dimensional, a polyhedron is three-dimensional, and a polytope is the general N-dimensional case. The name is apt: the bounded context graph has multiple genuinely orthogonal dimensions of variation, not a flat arrangement of boxes.

Each bounded context is its own hexagon: a domain at its core, ports on its boundary, adapters on the outside. What was previously "the outside world" now includes other bounded contexts. The key architectural rule is unchanged and extended: **no bounded context reaches directly into another's internals.** All cross-context dependencies are expressed as formal typed interfaces — ports — at the boundary. When the Scene context needs to know whether an action is legal, it calls a Rules port. It does not import the Rules Engine's modifier pipeline. When a rendering adapter needs entity conditions, it reads its own local projection of the event history, not the Scene's internal state map.

This constraint gives each bounded context the freedom to evolve its internals independently. The Rules Engine can restructure how it computes modifiers without breaking the rendering layer, as long as the events it emits maintain their Published Language contracts.

### 3.2 The O(N²) Problem and the Bus

If bounded contexts communicate through direct adapter pairs, then with N contexts there are up to N(N−1) directed adapter implementations. Every time a new context is added, every existing context that must react gets a new adapter. This is quadratic cost in the number of contexts — the practical reason large codebases become rigid as they grow.

The solution is a **typed event bus**. Each bounded context connects to the bus exactly once: it publishes typed events when its internal state changes, and subscribes to the events it cares about from other contexts. With N contexts, the adapter count is O(N). Adding a context costs one publisher and one subscriber, regardless of how many others must react.

This is the Mediator pattern applied at the architectural level. Coupling does not disappear — it moves. In the direct-adapter model, coupling is structural: Context A imports Context B's module. In the bus model, coupling is semantic: both contexts depend on the definition of the event type `DamageDealt`. Rename a field and every publisher and subscriber must be updated. This makes **the event schema registry the most important contract in the system**. It deserves the same discipline as a public API: versioning, deprecation, and migration paths. Section 7 addresses the design methodology for this contract.

### 3.3 The Event Bus as Meta-Hexagon

The event bus is itself a bounded context, forming a hexagon at the meta-level:

- **Domain:** event routing, schema validation, causal ordering, persistence, replay.
- **Ports:** the event schema registry — the Published Language is the bus's outward-facing interface.
- **Adapters:** the concrete implementation (Phoenix.PubSub, a synchronous in-memory test double, a persistent event store, an external broker).

From each bounded context's perspective, the bus is an external adapter — no different from a database. From the bus's perspective, every bounded context is its adapter. This creates **fractal self-similarity**: at the micro level, each context is a hexagon; at the meta level, the bus is a hexagon; at a higher level still, a coordination bus between federated system instances is a hexagon at the meta-meta level. The same pattern repeats at every level of abstraction.

The practical implication: the event bus must be encapsulated behind its own port — a behavior definition — just as `Gibbering.Ruleset` is a port for the rules context. Phoenix.PubSub is one adapter; a synchronous in-memory module makes tests deterministic; a persistent event store adds replay. Swapping implementations must not require touching any bounded context. If it does, the bus is not properly encapsulated.

---

## 4. Taxonomy

We now define the four levels of the taxonomy precisely, grounding each in the literature where an equivalent concept exists.

### 4.1 Dimension

A **dimension** is an orthogonal axis of variation in the system — a way the system varies that is independent of all its other variations. This is dimension in the MDSOC sense (Tarr et al., 1999). The polytope has five:

| Dimension | What it describes |
|---|---|
| Structural | The bounded context topology — which contexts exist and how they are organized |
| Temporal | The time axis — how the system evolves across different time scales |
| Behavioral | The state machines and their compositions — how the system flows |
| Presentational | The rendering and UI layer — how the system is seen and interacted with |
| Integration | The event bus — the meta-level communication fabric |

### 4.2 Parallel

A **parallel** is a cross-section of a dimension: a level or grain within that dimension at which multiple contexts coexist. The name is geometric — parallel planes intersect an axis at different positions without intersecting each other. The MDSOC literature's nearest equivalent is *hyperslice* (Tarr et al., 1999); DDD uses *subdomain* for the structural parallels specifically. Neither term generalizes consistently across all five dimensions. Parallel is coined here for that reason.

### 4.3 Context

A **context** is a bounded context in the DDD sense (Evans, 2003): a named boundary within which a specific domain model applies and is internally consistent. Multiple contexts coexist at each parallel as peers.

### 4.4 Aspect

An **aspect** is a concern that cannot be cleanly assigned to any single context because it cuts across multiple contexts and dimensions simultaneously. Aspect-Oriented Programming (Kiczales et al., 1997) defines aspects precisely this way. Security, observability, error handling, and schema validation are aspects. They are not bounded contexts. For intra-context sub-concerns, prefer *capability* or *facet*; "aspect" implies cross-cutting.

### 4.5 Relationship to Literature

The full term is the **reactive bounded context polytope**: a synthesis of MDSOC (dimensions), DDD (bounded contexts and Published Language), AOP (aspects), hexagonal architecture (Cockburn, 2005), and event-driven architecture. It is a genuine synthesis, not a renaming of existing work. The terms *polytope*, *parallel*, and *meta-hexagon* are coined here. All others are established.

---

## 5. Time, Events, and Ordering

### 5.1 Time as a Genuine Dimension

In a synchronous system, events happen instantaneously from the application's perspective. In an event-driven bus system, time becomes structural. A `DamageDealt` event produced at T₁ may be consumed at T₂ by a slow subscriber, replayed at T₃ for a late-joining spectator, stored and queried at T₄ by an audit log, and used at T₅ to rebuild state after a crash. The "current state" of any bounded context is not an independent snapshot — it is a *projection* of the event history up to a chosen point in time.

This is the core idea of *event sourcing*: store the ordered sequence of events that produced the current state, not just the current state itself. This has three consequences:

**Rewind and replay.** Any past state can be reconstructed by replaying the relevant events. This enables debugging ("what sequence produced this incorrect outcome?"), late-join spectating, and regression testing against recorded sessions.

**Backfilling new contexts.** A new analytics or observability context added today can process the complete event history from the beginning of time, not just events going forward.

**Causality as a first-class concern.** Events have not just timestamps but causal relationships. A `ConditionApplied` event was caused by a `DamageDealt` event, which was caused by an `AttackResolved` event, which was caused by an `AttackDeclared` command. Preserving this chain is required for correct animation sequencing, debugging, and any scenario where events must be replayed in causal order.

### 5.2 The Event Log as Unified Data, Storage, and Behavior

Traditional systems separate three concerns into three mechanisms: behavior leaves traces in application logs (if at all); domain state is stored in normalized mutable rows; current state is read from those rows. The mechanisms are different; the information is fragmented.

Event sourcing recombines them. The event log is simultaneously:

- **Data** — it is the source of truth. The `DamageDealt { entity_id, amount, source, timestamp }` event carries more semantic richness than a mutable `entity.hp = 42` row: it preserves the cause, the direction, and the moment.
- **Storage** — the event store is the primary durable record. No separate normalized database of current state is needed as the source of truth; current state is derived.
- **Behavior** — the complete event history is the state machine's transition trace. It can be replayed to reproduce any past state, projected to derive aggregates, or audited for any causal chain.

The event log therefore does not belong to any single layer or bounded context — it cuts across all of them vertically. This is exactly the temporal dimension's role: it is the historical axis that underlies the entire polytope. Every context writes to it; every projection reads from it; its schema is the Published Language materialized over time.

### 5.3 Event Integrity: Hash-Chained Logs

Borrowing from blockchain architecture, a **hash-chained event log** provides tamper-evidence without distributed consensus. Each event record stores `previous_event_hash = SHA256(previous_event_content)`. If any past event is altered, every hash after it is invalidated — making tampering detectable. This gives:

- Cryptographically guaranteed ordering (an event cannot be inserted between two others without breaking all downstream hashes).
- Tamper detection (useful for a trustworthy combat audit trail, anti-cheat, dispute resolution).
- No distributed protocol overhead — the chain requires only that appends are sequential.

Hash chaining borrows one property from blockchain (the linked ledger) while discarding the heavyweight property (distributed consensus over who may append). This separation is important: blockchain is a solution to a different problem — *Byzantine fault-tolerant distributed agreement* — and the consensus mechanism is expensive precisely because it must tolerate adversarial participants. A game engine's event store has a single trusted authority and requires no Byzantine tolerance.

Lighter alternatives — useful at different scales — include Lamport logical clocks (causal ordering without hash chaining, Lamport 1978) and optimistic concurrency with expected version numbers (the EventStoreDB model: each append declares the expected stream version; the store rejects the append if another write has intervened, forcing the writer to retry from the new version).

### 5.4 The Concurrent Event Problem

A hash-chained log requires a **single logical writer per chain**. This creates a fundamental tension in a system where multiple bounded contexts may emit events concurrently.

Suppose Context A emits event E₁ and Context B emits event E₂ at the same logical moment, both referencing the same `previous_event_hash`. The chain has a fork: two events claim to be the successor of the same previous event. A linear hash chain cannot represent this without resolving the fork into a total ordering. This is the distributed analogue of a git merge conflict on an append-only log, and it has the same root cause: two writers with a shared ancestor.

There are three principled resolutions:

**Single writer per chain.** One process owns the event store and serializes all appends. Every context submits events to this writer (via the command bus); the writer appends them in receipt order and assigns monotonically increasing sequence numbers. In The Gibbering Engine, SceneServer is the single authoritative state machine and the sole event emitter during a scene — all commands flow through it, and it produces all events from each command in a single atomic batch. Total ordering is trivially maintained: there is one writer, so no fork is possible. This is the correct and simplest resolution for any system where one process owns each event stream.

**Per-stream chains.** Each bounded context owns its own event stream with its own hash chain. There is no global chain, so no global fork is possible. Cross-stream causal relationships are tracked via a `causation_id` field on each event, pointing to the event in another stream that caused it. This preserves causal ordering (the partial order over happens-before relationships) without requiring global total ordering. Total ordering of concurrent events across streams is abandoned in favor of causal ordering — which is the theoretically correct position: Lamport (1978) showed that concurrent events (events where neither happened before the other) have no meaningful total order; any total ordering of concurrent events is arbitrary. Imposing one introduces false precision.

**Optimistic concurrency with expected version.** Each append operation declares the expected current version of the stream. If another write has intervened (incrementing the version), the store rejects the append. The writer reads the new version and retries. This resolves conflicts without a dedicated serializing process, at the cost of occasional retries. It is the EventStoreDB pattern and is correct for low-conflict scenarios.

The resolution for this system follows from the architecture: SceneServer is the single writer, and the per-session event stream naturally belongs to it. No concurrent writer problem exists at the scene level. For other contexts (campaign events, content events), per-stream chains with causation tracking is the appropriate model.

---

## 6. The Event Bus: A Hierarchical Composition

### 6.1 Semi-Formal Definition

The polytope model refers to "the bus" as though it were one mechanism. It is not. The bus is a hierarchical composition of lower-level transport mechanisms, each satisfying a different subset of a shared set of properties.

A mechanism B is a *bus* with respect to a set of components if it satisfies:

1. **Mediation** — components communicating through B hold no direct references to each other; all messages pass through B.
2. **Schema** — messages through B are typed according to a Published Language L(B) agreed upon by all participants at that level.
3. **Fan-out** — a message published once may be received by any number of recipients, from zero to N.
4. **Temporal decoupling** (degree) — the extent to which sender and receiver need not be simultaneously active; ranging from none to full persistence.
5. **Spatial decoupling** (degree) — the extent to which sender and receiver need not share a process, node, or machine.

Any mechanism satisfying properties 1 and 2 is a bus. Properties 3–5 characterize *which kind*.

### 6.2 Command Bus and Event Bus

The polytope contains not one bus but two, with structurally opposite characteristics:

A **command bus** has fan-out = 1 (exactly one recipient), tight temporal coupling (the sender waits for acknowledgement), and directed addressing (the sender specifies the recipient). This is the CQRS command side. In the BEAM, `GenServer.call` and `GenServer.cast` implement the command bus. Commands are not events and must not be routed through the event bus: conflating them removes the request/response semantics required to know whether a command succeeded.

An **event bus** has fan-out ∈ [0, ∞) (zero or more recipients), loose temporal coupling (the sender does not block on receiver processing), and unaddressed broadcast (the sender holds no reference to any receiver). This is the CQRS event side. In Phoenix, `PubSub.broadcast` implements the event bus. A persistent event store extends it to full temporal decoupling — messages survive receiver downtime and can be replayed.

These are not interchangeable. Every cross-context message is either a command or an event. No cross-context message should travel outside the compound bus. Direct module imports across a bounded context boundary violate this property regardless of how they are implemented at the language level.

### 6.3 The Vertical Bus Stack

At every level of the full vertical stack (see Section 10), a bus mechanism exists. The polytope's domain bus sits on top of, and is implemented by, the levels beneath it:

| Level | Mechanism | Fan-out | Temporal decoupling | Published Language |
|---|---|---|---|---|
| Hardware | IRQ / memory bus | N | None | Interrupt vectors |
| OS kernel | Pipes, signals, sockets | 1–N | Partial (kernel buffers) | POSIX protocol |
| BEAM VM | Process mailboxes | 1 | Partial (mailbox queues) | Erlang terms |
| OTP | GenServer call/cast | 1 | Partial (mailbox) | Application structs |
| Phoenix.PubSub | broadcast/subscribe | N | Session-level | Typed event structs |
| Event store | Append-only log + replay | N | Full (persistent) | Versioned typed events |
| External broker | Kafka, NATS, AMQP | N | Full + cross-runtime | Schema-registered events |

Each row is a bus at its level. Each higher-level bus is implemented over the level below it. Phoenix.PubSub runs over BEAM process mailboxes; BEAM mailboxes run over OS scheduler primitives; OS primitives run over hardware interrupts. The polytope's domain event bus corresponds to the Phoenix.PubSub and event store rows — the level at which messages carry domain semantics expressed in the Published Language.

### 6.4 The Compound Bus Definition

The polytope bus B is the pair (C, E) where:

- **C** is the command bus: mediated, fan-out = 1, addressed, typed by command schema Lc
- **E** is the event bus: mediated, fan-out ∈ [0, ∞), unaddressed, typed by event schema Le (the Published Language)
- **Lc ∩ Le = ∅**: command types and event types are disjoint
- Every cross-context message belongs to exactly one of C or E

The WebSocket transport (Phoenix wire protocol) is not part of B. It is the transport layer connecting the browser adapter to the server-side presentation context — session-scoped, not mediated between bounded contexts. It sits below the application polytope's bus in the vertical stack.

**Diagnostic rule.** If an event queue, dispatcher, or bus-like structure appears *inside* a bounded context, it is a symptom: either the context has grown too large (the internal bus is actually cross-context communication that should cross a boundary through B), or the communication is genuinely internal and should be a direct function call with no intermediate mechanism. No legitimate intermediate case exists.

---

## 7. Event Schema Design: A Development Methodology

### 7.1 The Published Language as Central Contract

Section 3.2 established that the event schema registry is the most important contract in the polytope. In a direct-adapter system, a wrong interface is a local error between two contexts. In a bus-mediated system, a wrong event schema is a system-wide error — every subscriber to that event type is affected. The schema's blast radius is proportional to its subscriber count.

This property demands a formal development methodology for the Published Language. The following mini-cycle describes the sequence from discovery through implementation.

### 7.2 Event Storming: Discovery Before Schema

**Event Storming** (Brandolini, 2021) is a collaborative workshop technique in which domain experts and engineers discover domain events before writing a single line of schema. Participants write domain events — past-tense facts from the domain language — on sticky notes and place them on a timeline: `DamageDealt`, `TurnEnded`, `SpellCast`, `PlayerJoined`. No implementation language, no struct definitions, no technical vocabulary.

Bounded context boundaries emerge from the exercise: clusters of sticky notes that stop making sense together mark a context seam. Commands — actions that cause events — are distinguished from events — facts that resulted from actions. Aggregates — the things that handle commands and emit events — are identified. Policies — "whenever X happens, do Y" — are made explicit.

This discovery phase is **informed by all bounded contexts but owned by none**. The Published Language is the polytope's shared artifact. No single context should own the event schema definition for events that cross its boundary — the schema belongs to the seam, not the context on either side.

### 7.3 Schema Specification

Once events are named and their producers and consumers identified, write the formal schema. At minimum, each event carries:

| Field | Purpose |
|---|---|
| `event_id` | Globally unique identifier for this event instance |
| `event_type` | String or atom identifying the schema version (e.g. `"damage_dealt_v2"`) |
| `occurred_at` | Wall-clock timestamp (UTC) of when the fact became true |
| `schema_version` | Integer version of this event type's schema |
| `causation_id` | The `event_id` (or command id) that caused this event — tracing causal chains |
| `correlation_id` | The top-level user action this event belongs to — grouping a cascade |
| `payload` | The typed, versioned, domain-specific content |

The `causation_id` and `correlation_id` fields are what allow the animation sequencer to know that `ConditionApplied` must be displayed after `DamageDealt` — they share a `correlation_id`, and the causal chain through `causation_id` establishes the order.

### 7.4 Consumer-Driven Validation

The constraint flows in one direction only: **consumers specify what they need; producers must satisfy all consumers.** A producer must not remove a field, rename a field, or change a field's type without verifying that no active consumer depends on it.

Consumer-driven contract testing (the Pact protocol) formalizes this: each consumer writes a contract declaring which fields it reads from each event. The producer's test suite runs all consumer contracts against its emitted events. If any consumer contract fails, the producer's build fails. This makes breaking changes visible before they ship.

Producers and consumers are independently deployable only when this discipline is enforced. Without it, changing an event schema is a coordination problem: all consumers must be updated simultaneously, which is the microservices equivalent of a distributed two-phase commit.

### 7.5 Versioning and the Breaking-Change Problem

Not all schema changes are equal:

- **Non-breaking (additive):** Adding a new optional field. Existing consumers ignore it; new consumers can use it. No coordination required.
- **Breaking:** Removing a field, renaming a field, or changing a field's type. Every consumer that reads that field must be updated before or at the same time as the producer change ships.

For breaking changes, the recommended pattern is **parallel versioning with a migration window**: ship `damage_dealt_v2` alongside `damage_dealt_v1`. Update consumers one by one to read from v2. Once all consumers are on v2, retire v1. The producer publishes both versions during the migration window.

The mutation analogy from Section 9 is precise here: a field rename in `DamageDealt` propagates to every subscriber exactly as a point mutation propagates to every protein expressed from that gene. The failure modes rhyme. Schema governance must be treated with the same discipline as any other public API.

---

## 8. The Five Dimensions Applied

This section applies the taxonomy to a concrete system — The Gibbering Engine — to make the abstract model tangible. The contexts named are illustrative; the dimensions are general.

### 8.1 Structural Dimension

**Core Domain parallel** — the system's strategic differentiator:
- *Rules Engine* — modifier pipeline, condition semantics, action economy, resource mathematics. If this is wrong, the game is wrong.
- *Content Catalogue* — reference data (races, classes, monsters, spells), content versioning, homebrew validation.

**Supporting Domain parallel** — enables the core, not the differentiator:
- *Campaign Lifecycle* — membership, content staging, session scheduling, archival, the preparation workflow.
- *Identity and Authorization* — user roles, permission gates, campaign membership scope.

**Generic Domain parallel** — commodity concerns replaceable by off-the-shelf solutions:
- *Observability* — metrics, structured logging, distributed tracing.
- *Notification and Social* — DM broadcasts, whispers, combat log, spectator feed.

### 8.2 Temporal Dimension

**Real-time parallel** (sub-second to seconds):
- *Event cascade sequencing* — causal ordering of events within a single command; animation synchronization.
- *Scene state machine transitions* — moment-to-moment phase changes and their guards.

**Session parallel** (minutes to hours):
- *Combat session management* — the active scene, turn order, running event log.
- *Session replay and spectating* — late-join state reconstruction, spectator feed.

**Persistent parallel** (days to forever):
- *Campaign archive* — session history, persistent entity state between sessions.
- *Content evolution* — rule versioning, schema migration, backward compatibility of the Published Language.

### 8.3 Behavioral Dimension

**Campaign machine parallel** (outermost, coarsest grain):
- *Campaign lifecycle states*: `created → preparation → active → archived`. Guards, transition actions, and saga workflows spanning multiple steps (invite → join → prepare → start session).

**Scene machine parallel** (composite state inside the campaign machine):
- *Scene phase states*: `lobby → exploration → initiative_rolling → in_combat → paused`. The scene machine runs only while the campaign is in `active` — a composite state in UML statechart terms.
- *Entity machines*: per-entity state for action economy, conditions, resource pools — orthogonal regions running concurrently during combat.

**Event sequence parallel** (finest grain):
- *Command handling* — inbound commands are validated, applied, and produce an ordered list of typed events.
- *Cascade chains* — a single command produces a causally ordered batch: `AttackDeclared → AttackResolved → DamageDealt → ConditionApplied`.

### 8.4 Presentational Dimension

**Map layer parallel** (inside the SVG viewport):
- *Isometric projection and tile rendering* — coordinate transformation, diamond geometry, depth sort.
- *Entity rendering* — sprite composition, depth ordering, selection and targeting overlays.
- *Effect and overlay rendering* — fog-of-war mask, area effect geometry, condition indicators, animation clips.

**UI chrome parallel** (screen-anchored, outside the SVG):
- *Player controls* — action bar, spell selection, resource display (spell slots, rage charges).
- *DM controls* — intervention panel, initiative strip, per-entity tooling, condition application.
- *System overlays* — pause screen, end-session modal, DM broadcast banners, whisper popups.

### 8.5 Integration Dimension

**Published Language parallel** (the event schema registry — the bus's port definitions):
- *Scene events*: `DamageDealt`, `ConditionApplied`, `EntityMoved`, `TurnAdvanced`, `PhaseTransitioned`
- *Campaign events*: `PlayerJoined`, `ContentStaged`, `SessionStarted`, `SessionArchived`
- *Content events*: `ClassRegistered`, `SpellUpdated`, `ContentVersionChanged`
- *Notification events*: `BroadcastSent`, `WhisperDelivered`

**Bus implementation parallel** (the bus's own adapters):
- *Real-time transport*: Phoenix.PubSub — fire-and-forget, low latency
- *Persistent store*: an event log adapter — enables replay and late-join
- *Test double*: synchronous in-memory bus — deterministic, no process overhead

---

## 9. Design Patterns by Dimension

Each dimension has a natural pattern language that emerges from its structural properties rather than being imposed.

**Structural dimension.** *Strategy* for the ruleset port: the engine delegates all mechanical decisions to whichever ruleset module is configured. `Gibbering.Ruleset` is already a Strategy pattern. *Chain of Responsibility* for modifier pipelines: each modifier has the opportunity to contribute or pass on. *Specification* for rule predicates: composable boolean conditions on game state. *Repository* and *Flyweight* for the content catalogue: reference data is shared by reference across all scene instances. *Prototype* for staging catalogue content into scene entities: a catalogue monster becomes a scene entity by copying its template and hydrating it with instance-specific state.

**Temporal dimension.** *Event Sourcing* as the foundational pattern. *Memento* for scene snapshots: checkpoint projected state at intervals so replay need not start from the beginning. *CQRS*: the write side handles commands and produces events; the read side maintains per-adapter projections. LiveView's socket assigns are informal read models — CQRS makes this explicit.

**Behavioral dimension.** *State* for each state machine: campaign lifecycle and scene phases are State pattern machines with guarded transitions and entry/exit actions. *Composite State* for the scene machine nested inside the campaign machine. *Saga* (Process Manager) for multi-step workflows: the invite → join → prepare → start flow spans multiple steps, multiple contexts, and needs compensating actions if any step fails.

**Presentational dimension.** *Composite* for the SVG element tree: tiles, entities, effects, and overlays are composable elements depth-sorted uniformly. *Visitor* for the rendering pass: a rendering visitor traverses the scene graph and emits SVG for each element type, keeping rendering logic out of the domain. *Template Method* for sprite rendering: each sprite type overrides specific strokes within a shared structural template.

**Integration dimension.** *Observer* for event subscriptions — the missing piece in most PubSub implementations is typed struct messages instead of bare tuples. *Event Aggregator* for collecting related events from one command into a single causally ordered payload before broadcasting: emit a cascade batch, not individual events. Subscribers receive the complete causal chain. *Mediator* for the bus itself: contexts do not negotiate communication with each other; the bus mediates all cross-context interaction.

**UML vocabulary.** From statechart notation: *composite state*, *orthogonal regions*, *history pseudostate*, *guard*, *entry and exit actions*. From component diagrams: *provided interface*, *required interface*, *port*. From BCE stereotypes: `«boundary»` for LiveView components and CLI tasks; `«control»` for SceneServer and saga coordinators; `«entity»` for Engine.State and domain structs.

---

## 10. The Full Vertical Stack and Deployment

### 10.1 From Hardware to Federation

The polytope as described is horizontal: bounded contexts at the application level, connected by an event bus. The same fractal structure extends vertically in both directions — downward through the software stack, upward through external services and federated systems:

**Hardware → Operating System → Virtual Machine / Runtime → Libraries and Frameworks → Application bounded contexts → External services → Federated systems**

Each layer is a bounded context for the layer above it. The OS provides a stable Published Language — POSIX — that abstracts over the hardware below. The BEAM VM is an adapter over the OS, translating OS threads and file descriptors into BEAM processes and Elixir's `File`, `Task`, and `:gen_tcp` modules. When you call `File.read/1`, you call through four distinct adapters: Elixir standard library → BEAM NIF → OS syscall → kernel filesystem driver.

This is Parnas's modular decomposition principle (Parnas, 1972): each layer hides a design decision from its neighbors. The OS hides hardware specifics. The VM hides OS specifics. Libraries hide protocol and algorithm specifics. This is also Dijkstra's layered architecture (THE system, 1968): a system in which each layer depends only on the layer below can be verified and evolved one layer at a time.

### 10.2 Third-Party Software

Third-party software appears at multiple vertical levels in two forms.

**In-process libraries** run inside your process and share your memory space. The correct discipline: write a port expressing what your domain needs (not what the library provides), then write a thin adapter translating between your port and the library's API. This anti-corruption layer (Evans, 2003) prevents the library's model from leaking into your domain. When the library releases a breaking change, changes its performance characteristics, or needs to be test-doubled, only the adapter changes.

**Out-of-process external services** are bounded contexts running in separate processes, typically remote. A payment processor, email delivery service, or third-party authentication provider each have their own Published Language (their API schema), release cadence, error model, and availability characteristics. The anti-corruption layer translates the external model into your domain model, normalizes errors, handles retries, and ensures the rest of your system never needs to know what the external service calls its fields.

The OS itself is the ultimate external bounded context — the one all software depends on but that depends on nothing above it. POSIX's forty-year stability results from treating the OS interface as a formal Published Language that cannot break without breaking every program that depends on it. The lesson scales.

### 10.3 Deployment Is an Adapter Decision

The bounded context decomposition is entirely independent of the deployment topology. In a traditional layered architecture, deployment and structure are conflated — changing the deployment requires thinking about the design. In the polytope, they are orthogonal.

The bounded context decomposition tells you *what* the system is. The deployment topology tells you *where* those contexts run. Every bounded context can run in a single BEAM process with a synchronous in-memory bus (a monolith — a legitimate deployment for an early-stage system). Contexts can be split into OTP applications in an umbrella project, communicating via node-local PubSub. They can be distributed across machines, where the bus becomes libcluster-extended PubSub or a dedicated broker (Kafka, RabbitMQ, NATS). The domain code is identical across all of these. Only the bus adapter changes.

This is what enables Fowler's "MonolithFirst" strategy (Fowler, 2015): start with everything in one process, validate the decomposition through actual use, then extract high-load or high-change contexts into separate deployments when a specific operational reason emerges — not speculatively. Deployment fits in the **Integration dimension's bus implementation parallel**: the concrete bus adapter is a deployment decision. Everything above the bus port boundary is deployment-agnostic.

---

## 11. Context-Awareness and the Polytope

Context-aware computing (Schilit and Theimer, 1994; Dey, 2001) addresses the same underlying problem as the polytope — how a system adapts to its environment — at a different scale. The concerns map precisely.

Dey's (2001) canonical definition — "Context is any information that can be used to characterize the situation of an entity" — maps directly to bounded context state in the polytope. The entity in Dey's sense is a bounded context; its situational information is its state map, the active scene phase, and the current entity conditions.

| Context-aware concept | Polytope equivalent |
|---|---|
| Context (Dey's definition) | Bounded context state + entity state map + scene phase |
| Context acquisition | Event bus subscriptions — typed events are published context changes |
| Context distribution | The event bus — the Published Language is the context schema |
| Context reasoning | Ruleset callbacks, state machine guards, modifier pipelines |
| Behavior adaptation | State machine transitions, ruleset dispatch |
| Context history | Temporal dimension — event sourcing is explicit context trajectory |

Dey's four primary dimensions appear as polytope equivalents:

| Dey's dimension | Polytope equivalent |
|---|---|
| Location | Entity grid coordinates, scene membership |
| Identity | Entity identity, player role, campaign membership |
| Activity | Scene phase, action economy state, active conditions |
| Time | Temporal dimension — event timestamps, causal ordering |

These are not analogies — they are the same concepts named differently. The scene phase `:in_combat` is situational context in Dey's precise sense. The entity's `conditions: [:paralyzed]` is situational context for that entity. `collect_modifiers(entity, action, state)` is context reasoning: given the entity's current situation, which rules apply?

**What the polytope does not absorb.** The context-aware literature devotes significant effort to *imperfect context* — sensor readings with error margins, inferred activity from ambiguous signals, conflicting sources (Henricksen and Indulska, 2004). For a game engine, game state is deterministic and authoritative; this gap is irrelevant by design. For systems that sense the physical world, an explicit context-provider bounded context would handle uncertainty before publishing clean typed events to the polytope. External physical context (GPS, proximity sensors) would be handled by a sensor-facing bounded context. The polytope absorbs it; it simply has no instance of it in this system.

**The theoretical claim.** Context-aware computing solved the adaptation problem for single applications: one system senses its environment and adapts. The polytope extends this to a distributed domain graph: N local context models, each maintaining its own situational state, synchronized through typed event distribution. The polytope is a *distributed context-aware architecture*. The behavioral dimension's state machines are a formalization of the context model at the system scale.

---

## 12. The Meta-Polytope: Lifecycle and Actors

### 12.1 The Development Lifecycle as a Polytope

The process by which the system is built and evolved is itself a structured system with bounded contexts, ports, and a Published Language — a polytope operating on the software polytope. Its bounded contexts:

- **Discovery and requirements** — domain experts, product owners, user research. Published Language: problem statements, user stories, acceptance criteria, the ubiquitous language of the domain being built.
- **Design** — architects and technical leads. Published Language: bounded context maps, port definitions, event schemas, architectural decisions.
- **Implementation** — developers. Published Language: programming language, internal codebase conventions.
- **Verification** — automated tests, QA, CI pipelines. Published Language: test specifications, coverage reports, pass/fail signals.
- **Deployment** — DevOps, infrastructure tooling, release management. Published Language: deployment configurations, infrastructure-as-code.
- **Observation** — monitoring, alerting, metrics, structured logs. Published Language: metrics schemas, alert definitions, log structures. Observation data closes the loop back into Discovery.

These contexts communicate via their own event chain: problem statements flow from Discovery into Design; design decisions flow into Implementation; implementation artifacts flow into Verification; verification gates Deployment; observation data closes the loop.

Conway's Law (Conway, 1968): organizations that design systems produce systems mirroring their communication structure. In polytope terms, the bounded context decomposition of the software tends to follow the bounded context decomposition of the team. Teams organized around functional layers (all frontend engineers together) produce layer-based systems resistant to independent evolution. Teams organized around bounded contexts produce clean bounded context boundaries.

### 12.2 Actors: Human and AI

**The human designer** is the primary actor in the meta-polytope — the initiating actor driving the entire process. The human provides domain knowledge (what the software must do and why), architectural judgment (identifying the right decomposition boundaries), creative direction, and validation (whether a produced artifact actually satisfies an intention). Brooks (1987) distinguished *essential* complexity — the inherent difficulty of the problem domain, which cannot be automated — from *accidental* complexity — the difficulties of representation and tooling, which can be reduced. Human judgment handles essential complexity.

**The AI assistant** is a `«boundary»` component at the interface between human judgment and the implementation context. It receives natural language descriptions of design decisions and produces code, documentation, and analysis. When participating in design rather than just implementation — synthesizing patterns, articulating implications of decisions — it operates more like a `«control»` component, orchestrating the transformation of design intent into structured artifacts. What the AI does not provide: genuine domain understanding (it pattern-matches on training data), persistent context across sessions, actual judgment (it optimizes for plausible output, not necessarily correct output), or agency (it responds, does not initiate). The AI is a powerful adapter, not a domain authority.

The documentation system — architecture documents, the issue tracker, memory files — is the **event store** that gives continuity across AI sessions. Each session starts stateless; the documentation is the replay log that reconstructs context. Design decisions are the events. Documentation is the materialized projection. The AI reads the projection to resume where the previous session ended. This is event sourcing applied to the development process.

### 12.3 What Is an Application?

An **application** is a specific instantiation of a subset of the bounded context polytope, with a chosen set of adapters, a chosen bus implementation, and a chosen deployment topology. The domain — the polytope of bounded contexts — is independent of any specific application instantiation. The same domain can be instantiated as a web application, a CLI tool, an API server, a background worker, or a test harness — differing in adapter set, bus implementation, and deployment topology, but sharing the domain entirely.

This is Cockburn's (2005) original claim extended to N dimensions: the domain must be equally driveable by a user, a test runner, a CLI invocation, or another service, with the domain code indifferent to which is driving it.

When discussing software: "the application" means one specific instantiation. "The system" or "the domain" means the polytope — the bounded contexts that constitute the core. Conflating them is the root cause of debates about "should the application do X?" that are actually debates about whether X belongs in the domain or in an adapter.

---

## 13. Discussion

### 13.1 Relationship to Game Engine Architecture

Game engines have independently developed analogous architectural patterns under different names. The Entity Component System (ECS) — the standard architecture in modern game engines (Unreal, Unity, BG3/Divinity) — separates entities (identity), components (state organized by concern), and systems (behavior operating on component sets). Components are a form of multidimensional decomposition: an entity can have a physics component, a rendering component, a rules component, and a networking component, each maintained by its own system. This is the structural dimension's decomposition at the runtime object level.

Unreal's Gameplay Ability System (GAS) formalizes the rules and effects layer as a distinct concern with its own event bus (Gameplay Events), its own attribute system, and its own tag-based context model. GAS is, in polytope terms, a formal implementation of the Rules Engine bounded context with a built-in command bus (ability activation) and event bus (gameplay tags). It converges on the same architectural insight from a different direction — that rules, attributes, and state are genuinely orthogonal concerns that should not be collapsed into a single monolithic character class.

### 13.2 The Event Log as Unified Data/Storage/Behavior

Section 5.2 argued that the event log unifies data, storage, and behavior into a single mechanism. The implications for system reasoning are significant. In a CRUD system, auditing requires a separate audit log mechanism (because the primary storage is mutable). Testing a specific historical scenario requires seeding a database to match a past state (which may no longer be reconstructible). Debugging a wrong outcome requires either logs (if they were comprehensive) or reproduction steps (which are often impossible).

In an event-sourced polytope, all three are immediate: the audit trail is the event log (the primary storage); testing a historical scenario means replaying the recorded event sequence; debugging a wrong outcome means replaying to the moment of failure with additional instrumentation. The event log earns its complexity cost in observability alone.

### 13.3 The Central Dogma Applied

The analogy between the central dogma of molecular biology (DNA → RNA → Protein) and the polytope's information flow (Commands → Events → State) is more than decorative. Both systems depend on *one-way information flow* as a load-bearing property. In molecular biology, violating the central dogma — reverse transcription — is both rare and disruptive; it is the exception, not the rule, and it requires specialized machinery. In the polytope, violating the one-way flow — allowing a context to mutate another's state directly, bypassing events — is the architectural equivalent: it breaks the coherence of the whole system, requires special-case handling everywhere, and is a symptom of a decomposition failure.

---

## 14. Limitations and Blind Spots

### 14.1 Context Uncertainty and Physical Sensing

The polytope assumes authoritative, deterministic state. Real-world systems that must infer context from imperfect sensors — the full subject of Henricksen and Indulska (2004) — require explicit uncertainty modeling. Adding probabilistic context would require a new class of bounded context (a context-inference context) with a Published Language that carries confidence scores or probability distributions rather than asserted facts. This is not a gap in the model's vocabulary — the model can accommodate it — but it is not addressed in this paper.

### 14.2 Formal Verification

This paper argues structurally and by analogy. It does not formally verify that the polytope model is consistent (no internal contradictions), complete (covers all cases of interest), or sound (the architectural rules prevent the failure modes they claim to prevent). Graph-theoretic formalization of the bounded context graph and formal specification of the bus properties would be required for such verification.

### 14.3 Quantitative Claims

The O(N²) vs O(N) adapter-count argument is made informally. In practice, not all N contexts communicate with all others — the actual adapter count is O(E) where E is the number of communication edges, which may be much less than N². The bus's actual cost savings depend on the topology of the communication graph and the cost of the event bus itself (schema registry maintenance, versioning overhead, operational complexity of a broker). These quantitative claims deserve empirical study.

### 14.4 Empirical Validation

The model is derived from design reasoning and pattern synthesis, not from controlled study of systems built with and without it. The claim that polytope decomposition produces lower coupling, faster independent evolution, and better observability than alternative architectures is argued structurally but has not been measured. Longitudinal studies of codebase evolution, deployment frequency, and defect rates in polytope-organized vs. traditionally-organized systems would provide the empirical evidence this paper lacks.

### 14.5 Operational Complexity of the Event Schema Registry

Treating the event schema registry as the most important contract introduces organizational and tooling requirements that the paper asserts but does not fully specify: who owns the registry, how changes are proposed and reviewed, what tooling enforces consumer-driven contracts in CI, and how the registry is versioned and distributed across teams. These are process and tooling design problems beyond the architectural model.

---

## 15. Future Work

### 15.1 Graph-Theoretic Formalization

The polytope is informally defined as a directed graph of bounded contexts connected by a typed event bus. A formal graph-theoretic definition would allow precise reasoning about properties such as: acyclicity constraints (can the event graph have cycles? under what conditions are they benign?), connectivity (which contexts can be deployed independently without the event bus?), and partition tolerance (which subsets of contexts can function correctly when the bus is partitioned?).

### 15.2 Tool Support for Schema Contract Enforcement

Consumer-driven contract testing (Section 7.4) is the operational mechanism for enforcing Published Language contracts, but current tooling (Pact) is oriented toward HTTP API contracts, not typed event struct contracts in BEAM languages. A tool that: (1) generates event consumer contracts from Elixir subscriber modules, (2) verifies producer compliance in CI, and (3) tracks the breaking-change blast radius of a proposed schema change, would make the methodology practical at scale.

### 15.3 Extension to Context Uncertainty

Integrating probabilistic context modeling into the polytope — for systems that must infer context from imperfect sensors — would require extending the Published Language to carry confidence scores, defining inference-bounded-contexts with appropriate ports, and establishing reasoning patterns for uncertain state in the behavioral dimension's state machines.

### 15.4 Federation and Multi-Instance Polytopes

The fractal self-similarity of the meta-hexagon suggests that multiple polytope instances (different deployments, different geographic regions, different tenants) can be federated by a coordination bus operating at the polytope level. The same bus formalism applies at every level. Specifying the Published Language at the federation level — what events flow between polytope instances and how cross-instance causality is tracked — is an open design problem.

### 15.5 Empirical Validation

Designing controlled or observational studies to test the polytope's claimed benefits — lower coupling, faster evolution, better observability — against alternative architectures in real production systems. Longitudinal codebase analysis (coupling metrics over time) and deployment frequency comparison would be appropriate measurement approaches.

---

## 16. Conclusion

Hexagonal architecture is a powerful model for isolating a domain from its infrastructure. Its limitation — one primary concern at the center — makes it insufficient for systems with multiple genuinely orthogonal concerns. The bounded context polytope extends hexagonal architecture to N dimensions by replacing the single hexagon with a directed graph of hexagons (bounded contexts) connected by a typed event bus. The O(N²) adapter-pair problem is resolved by mediating all cross-context communication through the bus, consolidating coupling onto the Published Language (the event schema registry).

The model introduces a four-level taxonomy — dimension, parallel, context, aspect — grounded in established literature (MDSOC, AOP, DDD) with minimal coinage (polytope, parallel, meta-hexagon). The compound bus B = (C, E) formalizes the distinction between the command bus (fan-out 1, addressed) and the event bus (fan-out N, broadcast), each appropriate for different cross-context communication semantics.

The concurrent event ordering problem in hash-chained logs is resolved by observing that total ordering requires a single logical writer per chain — the natural architecture for a single-authoritative-process state machine — and that causal ordering (partial order) is the theoretically correct replacement for systems with multiple concurrent writers.

The event schema design methodology — Event Storming, schema specification, consumer-driven validation, versioning policy — operationalizes the Published Language as a development practice, not just an architectural concept.

Context-aware computing is shown to be subsumed by the polytope at a higher level of abstraction: the polytope is a distributed context-aware architecture in Dey's (2001) formal sense, extending the single-application context-awareness model to N cooperating bounded contexts.

The development lifecycle is itself a polytope, with Conway's Law as the fundamental coupling between the organizational polytope and the software polytope. AI systems, properly understood, are `«boundary»` or `«control»` adapters in the meta-polytope — powerful and useful, but not domain authorities. The documentation system serves as the event store that provides continuity across stateless AI sessions.

The model is not formally verified, not empirically validated, and not fully operationalized — these are Future Work. What it provides is a coherent vocabulary, a consistent set of structural rules, and a body of analogies grounded in established literature that together make complex multi-concern systems easier to reason about, design, and evolve.

---

## Appendix A: The Biological Analogy

The polytope's structure has a precise biological analogue at every level of organization. The analogy is productive rather than decorative — it points to structural properties that are not otherwise obvious.

### A.1 The Molecular Level: Published Language and Event Flow

**The event schemas (the Published Language) are the genetic code.** The genetic code is the shared vocabulary that gives meaning to nucleotide sequences — the alphabet and grammar that all cellular machinery must agree on to communicate correctly. The event schema registry plays the same role.

**The persistent event store is DNA.** DNA is the authoritative, append-only record from which the organism's expressed state is derived. Everything the organism does or builds traces back to it. The event log is the same: the authoritative record from which all bounded context state is derived. Current state is always a materialized view over the event history.

**Events in flight through the bus are messenger RNA (mRNA).** mRNA is produced from a DNA template, carries a specific message from the nucleus to the ribosome, and is transient — degraded after translation. Individual events flowing through the bus are the same: produced from a domain action, typed and addressed to subscribers, ephemeral in fire-and-forget transport.

**Bounded contexts are cells.** Each cell contains the complete DNA but expresses only the genes relevant to its specialization. A liver cell and a neuron have identical DNA but radically different expressed proteins. Each bounded context has access to the complete event bus but subscribes only to the events relevant to its domain. Same bus, different expression.

**Read models and projections are proteins** — the expressed outputs derived from the genetic information. Proteins are what the organism actually does and builds. Read models are the projected state that adapters use for rendering and interaction.

| Biology | Architecture |
|---|---|
| Genetic code | Published Language (event schema vocabulary) |
| DNA | Persistent event store (append-only record) |
| mRNA | Event instances in flight through the bus |
| Nuclear membrane | Port boundary (regulated access) |
| Ribosome | Bounded context consumer |
| Protein | Read model / projected state |
| Cell | Bounded context (same bus, different subscriptions) |
| Organism | The whole system (the polytope) |

**The central dogma of molecular biology** — DNA → RNA → Protein — maps to Commands → Events → State. Information flows in one direction and cannot reverse. You cannot un-transcribe a gene. You cannot un-publish an event. State is derived from events, not the reverse. Both systems depend on this one-way information flow as a load-bearing property.

### A.2 The Two-Bus Distinction in Biology

The nervous system and the endocrine system are the biological command bus and event bus respectively.

The *nervous system* is the command bus: point-to-point (a neuron synapses to one specific target cell), fast (millisecond transmission), addressed (axons are wired to specific destinations), acknowledged (post-synaptic potentials confirm reception). This is `GenServer.call` at the biological level.

The *endocrine system* is the event bus: broadcast (hormones are released into the bloodstream and reach all cells), slow (minutes to hours), unaddressed (the hormone does not know its recipients), with fan-out determined by receptor presence — only cells expressing the appropriate receptor respond. This is `PubSub.broadcast` at the biological level. The receptor specificity *is* the subscription mechanism: a cell that does not express the insulin receptor does not respond to insulin, exactly as a subscriber that does not subscribe to `DamageDealt` does not receive it.

### A.3 The Vertical Bus Stack in Biology

Biology exhibits the same layered bus structure as the software stack:

| Level | Biological mechanism | Fan-out | Temporal decoupling | "Published Language" |
|---|---|---|---|---|
| Hardware | Ion channels, action potential | 1 | None | Voltage / ion concentration |
| Intracellular | Second messengers (cAMP, Ca²⁺) | N (within cell) | Seconds | Molecular signal cascades |
| Local chemical | Neurotransmitters (synaptic) | 1 | Milliseconds | Neurotransmitter identity + receptor |
| Systemic chemical | Hormones (endocrine) | N | Minutes to hours | Hormone + receptor specificity |
| Genetic | Gene expression, epigenetics | N | Hours to lifetime | Transcription factor binding sites |

Each row is a bus at its level. The action potential is implemented over ion channel physics. Hormonal signaling runs over the cardiovascular system — the network transport layer. Gene expression changes persist for the cell's lifetime and are heritable across cell division: the biological equivalent of the persistent event store.

### A.4 Context-Awareness in Biology

Dey's context framework — acquisition, distribution, reasoning, adaptation — maps directly to biological signal transduction:

Context *acquisition* is sensory reception: membrane receptors, photoreceptors, mechanoreceptors, chemoreceptors. Each is a port on the cell boundary that accepts specific molecular signals and translates them into intracellular signals. The receptor is the anti-corruption layer: it translates the external signal into the internal language of the cell.

Context *distribution* is the nervous and endocrine systems — the biological event bus.

Context *reasoning* is gene regulation: transcription factors assess the cell's current state (active signaling pathways, developmental stage, metabolic state) and determine which genes to express. This is `collect_modifiers(entity, action, state)` at the molecular level.

Context *adaptation* is differentiation and response: a muscle cell responds to acetylcholine by contracting; a liver cell responds to glucagon by releasing glucose. Same organism, same hormone, radically different adaptation based on cell identity — exactly as different bounded contexts respond differently to the same event.

### A.5 Polytope Taxonomy in Biology

| Biology | Polytope |
|---|---|
| Molecule | Data primitive (struct field) |
| Organelle | Sub-function within a context |
| Cell | Bounded context |
| Tissue | Parallel (cells of the same specialization) |
| Organ | Dimension (organized tissues serving one function) |
| Organ system | Cross-dimensional concern (aspect) |
| Organism | The polytope |

The organism's nervous and endocrine systems span all organs — they are aspects in the AOP sense, cross-cutting concerns that cannot be assigned to any single organ because they serve all of them. Security and observability in software are structurally identical.

### A.6 Development Lifecycle and Embryogenesis

An organism develops from a single cell through a precisely ordered sequence of context-driven adaptations. Each cell receives context signals (morphogens, physical gradients, cell-cell contacts) and adapts its gene expression accordingly. The developmental program is an event-sourced state machine: the zygote's initial state plus the ordered sequence of context events during development deterministically produces the adult organism. The organism cannot be understood at any developmental stage without the history of context changes that produced it.

The biologist's model of development: initial state + event history → current state. This is identical to the event sourcing claim. Biology discovered this architecture three billion years before we named it.

---

## References

**Foundational architecture**
1. Cockburn, A. (2005). *Hexagonal Architecture*. c2.com.
2. Dijkstra, E.W. (1968). The Structure of "THE" Multiprogramming System. *Communications of the ACM*, 11(5).
3. Parnas, D.L. (1972). On the Criteria To Be Used in Decomposing Systems into Modules. *Communications of the ACM*, 15(12).
4. Buschmann, F., Meunier, R., Rohnert, H., Sommerlad, P., Stal, M. (1996). *Pattern-Oriented Software Architecture, Vol. 1: A System of Patterns*. Wiley.

**Domain-Driven Design**
5. Evans, E. (2003). *Domain-Driven Design: Tackling Complexity in the Heart of Software*. Addison-Wesley.
6. Vernon, V. (2013). *Implementing Domain-Driven Design*. Addison-Wesley.

**Multidimensional separation of concerns**
7. Tarr, P., Ossher, H., Harrison, W., Sutton, S. (1999). N Degrees of Separation: Multi-Dimensional Separation of Concerns. *ICSE 1999*.
8. Kiczales, G. et al. (1997). Aspect-Oriented Programming. *ECOOP 1997*. LNCS 1241.

**Event-driven architecture and CQRS**
9. Young, G. (2010). *CQRS Documents*. cqrs.files.wordpress.com.
10. Hohpe, G. & Woolf, B. (2003). *Enterprise Integration Patterns*. Addison-Wesley.
11. Richardson, C. (2018). *Microservices Patterns*. Manning.

**Design patterns**
12. Gamma, E., Helm, R., Johnson, R., Vlissides, J. (1994). *Design Patterns: Elements of Reusable Object-Oriented Software*. Addison-Wesley.

**Deployment and organizational structure**
13. Newman, S. (2015). *Building Microservices*. O'Reilly.
14. Fowler, M. (2015). *MonolithFirst*. martinfowler.com.
15. Humble, J. & Farley, D. (2010). *Continuous Delivery*. Addison-Wesley.
16. Conway, M. (1968). How Do Committees Invent? *Datamation*, 14(4).

**Essential complexity and the limits of automation**
17. Brooks, F. (1987). No Silver Bullet: Essence and Accident in Software Engineering. *IEEE Computer*, 20(4).
18. Foote, B. & Yoder, J. (1997). Big Ball of Mud. *PLoP 1997*.

**Context-aware computing**
19. Schilit, B. & Theimer, M. (1994). Disseminating Active Map Information to Mobile Hosts. *IEEE Network*, 8(5).
20. Weiser, M. (1991). The Computer for the 21st Century. *Scientific American*, 265(3).
21. Dey, A.K. (2001). Understanding and Using Context. *Personal and Ubiquitous Computing*, 5(1).
22. Henricksen, K. & Indulska, J. (2004). A Software Engineering Framework for Context-Aware Pervasive Computing. *IEEE PerCom 2004*.

**Event schema design**
23. Brandolini, A. (2021). *Introducing EventStorming*. Leanpub.

**Event integrity and sequencing**
24. Lamport, L. (1978). Time, Clocks, and the Ordering of Events in a Distributed System. *CACM*, 21(7).
25. Nakamoto, S. (2008). Bitcoin: A Peer-to-Peer Electronic Cash System. *bitcoin.org*.
