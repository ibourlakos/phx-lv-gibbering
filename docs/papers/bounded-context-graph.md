# The Bounded Context Graph: A Named Synthesis Framework for Event-Driven Domain Architecture

**Authors:** Ioannis (John) Bourlakos · Claude Sonnet 4.6 (Anthropic)

**Note on terminology.** An earlier draft of this work used the term *polytope*. That term denotes a convex hull in N-dimensional Euclidean space with specific geometric properties (vertices, edges, faces, their incidence relationships). A directed graph of bounded contexts is not a polytope by any mathematical definition. The term is replaced here with *Bounded Context Graph* (BCG) — accurate and unambiguous.

---

## Abstract

We present the Bounded Context Graph (BCG), a named synthesis framework composing hexagonal architecture, Domain-Driven Design's bounded context model, multidimensional separation of concerns, and CQRS with event sourcing into a unified vocabulary. The BCG makes three claims: (1) a named four-level taxonomy for reasoning about dimensions of variation in complex domain systems; (2) an event schema design mini-cycle operationalizing the Published Language pattern; (3) a compound bus taxonomy distinguishing command routing from event broadcast. We situate each claim against its prior art, state its formal status explicitly, and identify where prior formalism validates, is consistent with, or potentially rejects the claim. The framework is evaluated against a game-engine application. Empirical validation and formal completion remain future work.

---

## 1. Introduction

### 1.1 Motivation

Cockburn (2005) isolates domain logic behind port interfaces, with concrete adapters connecting those ports to infrastructure. The model assumes a single primary concern at the center. When a system contains multiple genuinely orthogonal primary concerns — rules, content, lifecycle management, rendering, communication — each demands its own center, and hexagonal architecture provides no principled decomposition strategy.

The configuration that practitioners have converged on is a directed graph of bounded contexts communicating via a typed event bus (Vernon 2013; Richardson 2018; Dahan 2012). The BCG names and systematizes this configuration. It is a synthesis contribution in the sense of Gamma et al. (1994): naming and systematizing what practitioners already do to raise the discourse.

### 1.2 Contributions

**C1.** A named four-level taxonomy — dimension, cross-section, bounded context, aspect — synthesizing MDSOC (Tarr et al. 1999) and AOP (Kiczales et al. 1997) terminology with DDD vocabulary (Evans 2003).

**C2.** An event schema design mini-cycle for operationalizing the Published Language pattern as a repeatable process: Event Storming → schema specification → consumer-driven validation → versioning policy.

**C3.** A compound bus distinction B = (C, E_b), where C is the command bus (fan-out = 1, addressed) and E_b is the event bus (fan-out ≥ 0, broadcast), with a sketch of their placement in the vertical transport stack.

The BCG's structural claim — a directed graph of bounded contexts connected by a typed event bus — is not novel. It is the content of Vernon's reactive DDD, Dahan's autonomous components, and standard event-driven microservices decomposition. The contributions above are what differentiates the BCG from that literature.

### 1.3 Paper Organization

§2 reviews prior art. §3 defines the BCG. §4 presents the taxonomy. §5 addresses temporal ordering and read models. §6 defines the compound bus. §7 presents the schema methodology. §8 covers integration patterns. §9 applies the framework. §10 states the formal status of each claim. §11 discusses relationship to prior art. §12 states limitations. §13 proposes future work. §14 concludes.

---

## 2. Background and Prior Art

### 2.1 Hexagonal Architecture

Cockburn (2005): application logic behind abstract port interfaces; concrete adapters implement those ports; the core imports nothing from adapters. Limitation: implies a single center.

### 2.2 Domain-Driven Design

Evans (2003): bounded context as a named boundary within which a domain model is internally consistent. Context map: the document of inter-context relationships and their integration patterns (Vernon 2013). Published Language: the shared, explicitly versioned vocabulary for inter-context communication.

Vernon's reactive DDD (2011–2013) describes exactly the configuration the BCG names: bounded contexts communicating via typed domain events over a message bus. This is the primary prior art for the BCG's structural claim.

### 2.3 Multidimensional Separation of Concerns

Tarr et al. (1999): single-axis modular decomposition forces N concerns to coexist in each module. MDSOC introduces dimensions (orthogonal axes of variation) and hyperslices (cross-sections perpendicular to a dimension). The BCG uses dimension in this sense. Orthogonality is MDSOC's foundational requirement (§4.3).

Kiczales et al. (1997): aspect-oriented programming for cross-cutting concerns. The BCG uses aspect in this sense.

### 2.4 CQRS and Event Sourcing

Young (2010): command-query responsibility segregation. Commands (write side, fan-out 1) are structurally distinct from events (read side, fan-out N). Event sourcing: the append-only event log as primary source of truth. Projections derive current state from event history.

### 2.5 Event-Driven Microservices

Richardson (2018) covers event sourcing, sagas for distributed workflows, and consumer-driven contract testing in microservice architectures. This is the primary reference for the practical patterns the BCG assembles. Hohpe and Woolf (2003): canonical message-based integration patterns including Event Aggregator, Message Broker, and Publish-Subscribe.

### 2.6 The Actor Model

Hewitt, Bishop, and Steiger (1973): concurrent computation via message-passing actors with local state, no shared memory. Actors process messages sequentially. Erlang/OTP instantiates this model. A BCG bounded context whose write side is a GenServer is an actor in this sense. The sequential processing guarantee directly validates the single-writer contract (§5.2, §10).

### 2.7 SEDA

Welsh, Culler, and Brewer (2001): Staged Event-Driven Architecture. Stages connected by bounded queues, each with its own thread pool. Structural analogy to BCG: stage ≈ bounded context, queue ≈ event channel. Decomposition criterion differs: SEDA stages are defined by processing load characteristics; BCG contexts by domain boundaries.

### 2.8 Process Calculi

Hoare (1978): CSP. Milner (1980): CCS. Milner, Parrow, and Walker (1992): π-calculus. These provide the formal apparatus for specifying concurrent message-passing systems with typed channels, fan-out, and temporal ordering. The bus definition in §6.3 is a natural-language sketch of properties that CSP or π-calculus would formalize completely. We acknowledge this gap; §13.2 proposes the completion.

### 2.9 CloudEvents

CNCF (2018): a production specification for event schema definition and transport, covering envelope fields (specversion, type, source, id, time, datacontenttype, data), versioning conventions, and transport bindings. The BCG's event schema methodology (§7) addresses the design process; CloudEvents addresses the wire format. Any implementation should evaluate CloudEvents as a baseline envelope before defining a proprietary format.

### 2.10 Self-Contained Systems

Tilkov et al.: each system unit owns its UI, logic, and data; communication via asynchronous events. Structurally identical to BCG bounded context decomposition. The BCG adds the dimensional taxonomy and compound bus hierarchy.

### 2.11 C4 Model

Brown (2018): Context, Container, Component, Code. The BCG's *bounded context* level corresponds to C4's Container level; *cross-section* corresponds to a grouping of Containers sharing a concern. The BCG adds dimensional analysis where C4 adds drill-down levels. The two models are complementary, not competing.

### 2.12 DCI Architecture

Coplien and Bjørnvig (2010): separate Data, Context, and Interaction concerns. The BCG's structural dimension addresses a related decomposition problem; the DCI distinction between context-free data and context-dependent behavior appears within the BCG's bounded context as the separation between domain entities and command handlers.

---

## 3. The Bounded Context Graph

### 3.1 Definition

**Definition 3.1 (Bounded Context Graph).** A BCG is a directed labeled graph G = (V, E, τ, π) where:

- V is a finite set of **bounded contexts**, each a hexagonal unit (domain, port definitions, adapters).
- E ⊆ V × V is a set of directed **integration edges**.
- τ: E → {Conformist, Customer-Supplier, Anti-Corruption-Layer, Published-Language, Shared-Kernel, Open-Host-Service} labels each edge with its integration pattern.
- π: E → {command, event} classifies each edge as command-typed (fan-out 1) or event-typed (fan-out ≥ 0).

**Invariant (I1 — No Internal Access).** For any u, v ∈ V with u ≠ v: no module in u imports from the internal domain model of v. All cross-context dependencies are expressed as typed port interfaces.

**Invariant (I2 — Bus Mediation).** All event-typed edges (π(e) = event) are mediated by the compound bus B (§6). Command-typed edges may be direct synchronous calls through a port interface.

### 3.2 Adapter Topology and the Bus Argument

For N contexts with direct bilateral adapters, the maximum adapter count is N(N-1). The bus replaces this with 2|V| bus connections plus a schema registry defining |E_b| event types, where E_b ⊆ E is the event-typed edge set.

**Proposition 3.2.** The bus reduces worst-case adapter count from O(N²) to O(N + |E_b|).

**Qualification.** This is a worst-case comparison (complete graph vs. bus-mediated graph). In sparse communication topologies — where most contexts do not need to react to most events — |E_b| may be small relative to N, and the bus adds overhead (schema registry, versioning, fan-out machinery) without proportionate adapter savings. As noted in §12.3, the actual edge count E is O(E_b), which may be much less than N². The bus is justified when: (a) true fan-out exists (multiple subscribers to the same event type), (b) publisher/subscriber release cycles must be decoupled, (c) the communication topology evolves independently of either context, or (d) a single observation point for inter-context events is required.

### 3.3 Port Classification

Ports are synchronous (query or command ports) or asynchronous (event publisher or subscriber ports). Invariant I2 does not prohibit synchronous inter-context calls. Customer-Supplier seams may use synchronous port calls where the calling context must block on a result before proceeding (e.g., Scene context calling a Rules port to validate an action). Published Language seams use asynchronous event publication where the producer must not couple to which consumers exist.

---

## 4. Dimensional Taxonomy

### 4.1 The Four Levels

| Level | Name | Definition |
|---|---|---|
| 1 | Dimension | An axis of variation in the system; corresponds to MDSOC's dimension |
| 2 | Cross-section | All entities at a given position on a dimension; corresponds to MDSOC's hyperslice |
| 3 | Bounded Context | An autonomous domain unit; a node in G |
| 4 | Aspect | A cross-cutting concern spanning multiple contexts; corresponds to AOP's aspect |

### 4.2 The Five Dimensions

| Dimension | What it describes |
|---|---|
| Structural | Context topology — which contexts exist, how they relate |
| Temporal | Time axis — event sequencing, causality, state history, read models |
| Behavioral | State machines and workflows — how the system executes |
| Presentational | Rendering and UI — how the system presents information |
| Integration | The communication fabric — the event bus and its schema |

### 4.3 Orthogonality Discussion

MDSOC's foundational requirement is that dimensions be genuinely independent axes of variation: a change along dimension D1 at context C1 does not require a change along dimension D2 at any context C2. We identify two tensions:

**Temporal–Behavioral entanglement.** State machine transitions (Behavioral) are triggered by events ordered on the time axis (Temporal). A change in the event model may require a corresponding change in state machine guard conditions. These dimensions are separable — a context can evolve its transition logic without changing its event log format, and vice versa — but strict independence under MDSOC's criterion has not been demonstrated.

**Integration as aspect.** The Integration dimension describes how the other four communicate. It may be more accurately an aspect (a cross-cutting concern in the AOP sense) than a peer dimension. If so, the claim of five independent dimensions should be reduced to four dimensions plus one cross-cutting aspect.

Both tensions are unresolved. The dimensional taxonomy is proposed as a practical vocabulary, not as a proven MDSOC-compliant decomposition. §13.1 proposes the formal analysis needed to resolve them.

---

## 5. Temporal Ordering and Read Models

### 5.1 Event Envelope

Every domain event carries:

| Field | Purpose |
|---|---|
| `id` | Unique event instance identifier (UUID v4) |
| `correlation_id` | Top-level user action identifier; groups a cascade |
| `causation_id` | Immediately preceding cause in the causal chain |
| `stream_id` | The event stream this event belongs to |
| `sequence` | Monotonically increasing integer within the stream |
| `schema_version` | Schema version of this event type |
| `payload` | Typed domain-specific content |

### 5.2 Single Writer Per Stream

**Proposition 5.1 (Single Writer Correctness).** If exactly one process P is the authoritative writer for stream s, then the sequence of events on s is a total order, and no concurrent write conflict can occur on s.

*Justification.* A GenServer processes messages from its mailbox sequentially (actor model: Hewitt et al. 1973). If all writes to stream s are mediated by a single GenServer, writes are serialized by the mailbox ordering, and no two writes share a sequence number. ∎

**Corollary.** Under the OTP supervision model, the single-writer contract can be stated as: SceneServer is the sole process with write access to the scene event stream. All state changes are submitted as commands to SceneServer via the command bus; SceneServer processes them sequentially and emits the resulting event batch.

This claim is **validated** by the actor model; it is not novel. It is restated here as a hard architectural invariant, not a guideline.

### 5.3 CQRS Read Models

The write side (SceneServer) does not push its internal state struct to subscribers. Subscribers maintain independent projections over the event stream. The write side and read side are structurally separated: the write side's state type is not exported to adapters. Adapters subscribe to events and project only the fields they require.

Practical benefits: information hiding (player view never receives DM intervention state); independent evolution (restructuring a projection does not touch SceneServer); temporal replay (spectator or audit view reconstructs any past state by replaying events). Projection rebuild cost is amortized by checkpointing (Memento pattern: snapshot + events-since-snapshot).

---

## 6. The Compound Bus

### 6.1 Command Bus and Event Bus Distinguished

**Definition 6.1 (Command Bus C).** A channel with fan-out = 1, directed addressing (sender specifies recipient), synchronous-tolerant (sender may block for a reply), and typed by command schema L_C.

**Definition 6.2 (Event Bus E_b).** A channel with fan-out ∈ [0, ∞), broadcast (sender holds no reference to recipients), temporally decoupled (sender does not block on subscriber processing), and typed by event schema L_E (the Published Language).

**Definition 6.3 (Compound Bus).** B = (C, E_b) where L_C ∩ L_E = ∅. Every cross-context message belongs to exactly one of C or E_b.

### 6.2 Vertical Transport Stack

The event bus is a composition across transport layers:

| Layer | Mechanism | Fan-out | Temporal decoupling | Schema level |
|---|---|---|---|---|
| OS | Pipes, signals, sockets | 1–N | Partial | POSIX |
| BEAM VM | Process mailboxes | 1 | Partial | Erlang terms |
| OTP | GenServer call/cast | 1 | Partial | Application structs |
| Phoenix.PubSub | broadcast/subscribe | N | Session-scoped | Typed event structs |
| Event store | Append-only log | N | Full (persistent) | Versioned events |
| External broker | Kafka, NATS, AMQP | N | Full + cross-runtime | Schema-registered events |

The BCG's domain event bus corresponds to the Phoenix.PubSub and event store rows. All event-typed edges must be mediated through a named behaviour (`Gibbering.EventBus` or equivalent). The concrete adapter — PubSub, in-memory test double, external broker — is a deployment decision; the port boundary is not.

### 6.3 Formal Sketch

The following is a natural-language sketch in CSP-adjacent notation. It is a design vocabulary, not a formal specification. A rigorous treatment would use CSP (Hoare 1978) or π-calculus (Milner et al. 1992).

Let P_i denote bounded context i. Each context has a publication channel pub_i and subscription channels sub_i(t) for event types t ∈ T. Bus B provides:

```
publish(P_i, e: Event(t)) → ∀ j ∈ subscribers(t): deliver(P_j, e)
```

Delivery is: (a) asynchronous — P_i does not block on deliver; (b) ordered per stream — for stream s, events are delivered in sequence order; (c) not ordered cross-stream — concurrent events in different streams have no guaranteed relative delivery order. This is consistent with Lamport's (1978) result that concurrent events (neither happened before the other) have no meaningful total order; imposing one introduces false precision.

The command bus provides:

```
call(P_i, cmd: Command(t), addr: P_j) → receive(P_j, cmd) → reply(P_j, r) → P_i
```

where P_i blocks until reply. Addresses are statically determined at compile time (the calling context knows its dependency); subscriptions are registered at runtime.

**Formal status.** The properties in this sketch — typed channels, fan-out, delivery ordering, sender non-blocking for events — are expressible in CSP and π-calculus. A full process-algebraic specification would constitute formal validation of the bus semantics. Without it, Definition 6.3 is a structural description, not a formal specification.

---

## 7. Event Schema Design Methodology (C2)

### 7.1 Overview

The event schema is the system's most important contract. Its blast radius is proportional to subscriber count. We propose a five-step mini-cycle:

1. **Event Storming** (Brandolini 2013): discover domain events before schema. Domain experts write past-tense domain facts on stickies placed on a timeline. No implementation vocabulary. Bounded context seams emerge where clusters of events stop making sense together.

2. **Schema Specification**: for each discovered event, specify: event type (namespaced by bounded context), schema version, envelope fields (§5.1), typed payload fields. Output: a schema registry entry.

3. **Consumer-Driven Validation**: each consuming context specifies which fields it requires. Producer test suites run all consumer contracts. If any consumer contract fails, the producer build fails. This is Pact-style contract testing (Richardson 2018) applied to event schemas.

4. **Versioning Policy**: additive changes (new optional fields) are non-breaking. Removing, renaming, or retyping fields is breaking. Breaking changes require version increment and parallel-versioning during a migration window.

5. **Deprecation**: old schema versions are deprecated with an explicit deadline communicated to all subscribers.

### 7.2 Event Cascade (Event Aggregator Pattern)

A command produces a causally ordered event batch, not independent broadcasts. Example: AttackDeclared → [AttackResolved, DamageDealt, ConditionApplied]. The command handler returns {new_state, [%Event{...}]}. The entire batch is emitted atomically via broadcast_batch/2 after successful command processing. Each event in the batch carries causation_id linking it to its predecessor. Subscribers requiring causal order reconstruct it from the causation_id chain without relying on arrival order.

This is Hohpe and Woolf's (2003) Event Aggregator pattern applied to the command→event lifecycle.

### 7.3 Relationship to CloudEvents

CloudEvents (CNCF 2018) specifies the envelope fields for the same problem: specversion, type, source, id, time, datacontenttype, data. The §5.1 envelope is compatible with CloudEvents. Any implementation should evaluate adopting CloudEvents as the wire format rather than defining a proprietary envelope.

---

## 8. Integration Patterns at Context Seams

Every edge in G must be labeled with its integration pattern (τ, §3.1). The labeling is required, not optional: implicit patterns become invisible to code review.

| Pattern | Integration rule |
|---|---|
| Conformist | Downstream accepts upstream model; translates internally |
| Customer-Supplier | Upstream maintains contracts negotiated with downstream; synchronous ports acceptable |
| Anti-Corruption Layer | Downstream wraps all upstream calls in a translation layer; upstream model never leaks into downstream internals |
| Published Language | Event bus subscription; neither context's internal model is the schema |
| Shared Kernel | Shared module; changes require joint coordination |
| Open Host Service | Upstream publishes a stable API; multiple downstreams conform independently |

All event bus subscriptions are Published Language seams. All synchronous Customer-Supplier calls are protected on the downstream side by an Anti-Corruption Layer that translates the port response into internal domain types.

The context map — a document enumerating all seams and their patterns — is a required artifact. Without it, seam patterns are implicit and violations are invisible during code review.

---

## 9. Application: Game Engine

The Gibbering Engine (a turn-based D&D 5e tactical grid game) instantiates the BCG as follows:

| Context | Module Prefix | Primary seam type |
|---|---|---|
| Scene | Gibbering.Scene | Published Language (event publisher) |
| Rules Engine | Gibbering.Rules | Customer-Supplier (synchronous query port) |
| Content Catalogue | Gibbering.Catalogue | Customer-Supplier (read-only reference) |
| Campaign Lifecycle | Gibbering.Campaign | Published Language (event publisher) |
| Identity & Authorization | Gibbering.Identity | Conformist (upstream to Campaign) |
| Observability | Gibbering.Observability | Published Language (subscriber only) |
| Notification | Gibbering.Notification | Published Language (subscriber only) |
| Bus | Gibbering.EventBus | Infrastructure context |

**SceneServer invariant.** SceneServer is the single writer for the scene event stream (Proposition 5.1 applies). All scene state changes are submitted as commands to SceneServer. SceneServer processes commands sequentially (actor model guarantee), produces a causally ordered event batch, and emits the batch through the bus. No other process writes to the scene stream.

---

## 10. Formal Status of Claims

This section makes explicit the formal status of each BCG claim. The categories are:

- **Validated**: prior formalism directly guarantees the property.
- **Consistent**: the claim is consistent with prior work; formal proof not given here.
- **Conjectured**: the claim is proposed without formal support; may be provable.
- **Potentially rejected**: prior formal criteria may fail the claim on rigorous application.
- **Novel, requires formal treatment**: the claim has no direct prior art; formal completion is future work.

| Claim | Status | Basis |
|---|---|---|
| BCG directed graph structure | Consistent | Vernon 2013, Richardson 2018 — prior art validates direction, not novelty |
| Single-writer contract correctness | Validated | Actor model (Hewitt et al. 1973): sequential mailbox processing guarantees no concurrent fork |
| Bus B = (C, E_b) with disjoint schemas | Consistent | CQRS (Young 2010): write/read separation; the bus formalizes it structurally |
| Bus properties expressible in CSP/π-calculus | Conjectured | Hoare 1978, Milner et al. 1992: the formal apparatus exists; proof not given here |
| Five dimensions are orthogonal | Potentially rejected | Tarr et al. (1999) independence criterion: Temporal–Behavioral entanglement and Integration-as-aspect may fail the criterion on rigorous application |
| Event cascade (Aggregator) pattern | Validated | Hohpe and Woolf (2003): direct instantiation of the Event Aggregator pattern |
| Consumer-driven schema validation | Consistent | Richardson 2018 (Pact): the methodology is a direct application of consumer-driven contract testing to event schemas |
| Schema envelope compatible with CloudEvents | Validated | CNCF CloudEvents v1.0: field-level compatibility confirmed |
| Context-awareness expressible in BCG | Consistent | Dey 2001: plausible concept-level mapping; bijective subsumption not proven |
| O(N²) → O(N) adapter reduction | Consistent, qualified | Graph theory: worst-case comparison only; sparse topologies E_b << N² weaken the argument |
| Bus port pattern (swappable adapter) | Validated | Cockburn 2005: direct application of the port-and-adapter discipline to the bus itself |

**Key implications.** The claim most at risk of formal rejection is the five-dimension orthogonality claim. If Tarr et al.'s independence criterion is applied, the Temporal–Behavioral entanglement must either be resolved by a formal argument or acknowledged as a reduction of the taxonomy to four dimensions plus one aspect. The claim most valuable to formalize is the bus definition: a process-algebraic treatment would constitute a genuine formal contribution and validate the delivery semantics proposed in §6.3.

---

## 11. Discussion

### 11.1 Differentiation from Vernon's Reactive DDD

The BCG's structural claim is Vernon's reactive DDD. The BCG adds: (C1) a named four-level taxonomy; (C2) an event schema mini-cycle; (C3) a compound bus taxonomy with a sketch toward process-algebraic formalization. Teams familiar with Vernon's reactive DDD will find the BCG an elaboration of familiar territory.

### 11.2 Relationship to the Actor Model

A BCG bounded context whose write side is a GenServer is an actor in Hewitt's sense. The actor model provides the computational substrate; the BCG adds organizational and schema vocabulary. The single-writer contract follows directly from actor-model guarantees (§5.2, §10). OTP supervision trees provide the fault-tolerance and restart semantics for the bounded context's write-side process; the BCG does not prescribe supervision strategy.

### 11.3 Relationship to SEDA

SEDA (Welsh et al. 2001) and the BCG share structural form: bounded stages/contexts connected by queues/events. The decomposition criteria differ (processing load vs. domain boundaries). The two frameworks can be applied simultaneously: SEDA for intra-context concurrency management, BCG for inter-context domain organization.

### 11.4 Context-Awareness

Dey's (2001) context dimensions — location, identity, activity, time — map to BCG primitives: entity grid coordinates, Identity context, scene phase, temporal dimension. The mapping is suggestive and practically useful for applying BCG vocabulary to context-aware systems. It does not constitute subsumption: bijective mapping with no residue on either side has not been demonstrated. We claim only that context-aware systems are *naturally expressible* in BCG terms.

---

## 12. Limitations

**L1 — Orthogonality unproven.** The five-dimension claim requires a formal independence test (§4.3). Temporal–Behavioral entanglement and Integration-as-aspect may reduce the taxonomy under Tarr et al.'s criterion.

**L2 — Bus formalism incomplete.** §6.3 is a design vocabulary sketch. Delivery semantics, failure model, and subscriber idempotency requirements are not formally specified. A process-algebraic treatment is required for the definition to qualify as formal.

**L3 — Single empirical case.** The framework is evaluated against one application at development stage. Claims about scalability, team autonomy, and operational simplicity are structural arguments, not empirical results.

**L4 — CloudEvents not adopted.** The schema envelope in §5.1 is compatible with but not identical to CloudEvents. Any implementation should audit against CloudEvents v1.0 before defining a proprietary format.

**L5 — Migration cost not addressed.** The BCG describes target-state architecture. Migration from a layered monolith — particularly database ownership boundary migration across contexts — is not addressed.

**L6 — Novelty of structural claim.** The primary structural claim (directed graph of bounded contexts on a typed event bus) is not novel. This is stated in §1.2 and §1.3 and should be stated in any abstract submission.

---

## 13. Future Work

### 13.1 Formal Orthogonality Analysis

Apply Tarr et al.'s (1999) independence criterion to the five BCG dimensions. Define the criterion formally: a change in dimension D_i at context C_a does not require a change in dimension D_j at context C_b, for i ≠ j. Verify against the game engine application. Expected outcome: the criterion may reject Temporal–Behavioral orthogonality, reducing the claim to four dimensions.

### 13.2 Process-Algebraic Bus Specification

Formalize the bus in CSP or π-calculus. Specify: typed channels, delivery semantics (at-least-once vs. exactly-once), failure model (subscriber crash during delivery), and subscriber idempotency requirements. Verify the specification against the informal properties in §6.3.

### 13.3 TLA+ Verification of Single-Writer Contract

Model the SceneServer single-writer protocol in TLA+. Verify that under concurrent command submission, no two events share a stream sequence number, and no event is emitted before its predecessor in the causal chain.

### 13.4 Empirical Comparative Study

Apply the BCG to two or more additional domain-complex systems. Compare architectural coupling metrics, team coordination cost, deployment frequency, and incident rate against comparable systems using alternative decomposition strategies.

### 13.5 Migration Playbook

Develop a systematic migration path: event stream extraction, database ownership boundary migration, ACL insertion at existing direct inter-module calls.

---

## 14. Conclusion

The BCG names and systematizes a configuration that practitioners have independently converged on: a directed graph of bounded contexts communicating via a typed event bus. The structural claim is prior art (Vernon 2013; Richardson 2018); the three contributions are a named taxonomy, an event schema mini-cycle, and a compound bus distinction.

The formal status of claims is explicitly stated in §10. The claim best supported by prior formalism is the single-writer contract (validated by the actor model). The claim most at risk of formal rejection is the five-dimension orthogonality claim (Tarr et al.'s independence criterion may not be satisfied for Temporal–Behavioral and Integration). The claim most valuable to complete formally is the bus specification (a process-algebraic treatment would constitute a genuine formal contribution).

The BCG is evaluated against one application at development stage. Empirical validation and formal completion are open problems.

---

## References

[1] Cockburn, A. (2005). *Hexagonal Architecture*. alistair.cockburn.us.

[2] Evans, E. (2003). *Domain-Driven Design*. Addison-Wesley.

[3] Vernon, V. (2013). *Implementing Domain-Driven Design*. Addison-Wesley.

[4] Vernon, V. (2011–2013). *Reactive Domain-Driven Design*. Conference presentations and articles.

[5] Tarr, P., Ossher, H., Harrison, W., Sutton, S. M. (1999). N degrees of separation: Multi-dimensional separation of concerns. *ICSE 1999*, pp. 107–119.

[6] Kiczales, G. et al. (1997). Aspect-oriented programming. *ECOOP 1997*, LNCS 1241, pp. 220–242.

[7] Young, G. (2010). *CQRS Documents*. cqrs.files.wordpress.com.

[8] Hohpe, G. and Woolf, B. (2003). *Enterprise Integration Patterns*. Addison-Wesley.

[9] Richardson, C. (2018). *Microservices Patterns*. Manning.

[10] Hewitt, C., Bishop, P., and Steiger, R. (1973). A universal modular ACTOR formalism for artificial intelligence. *IJCAI 1973*, pp. 235–245.

[11] Welsh, M., Culler, D., and Brewer, E. (2001). SEDA: An architecture for well-conditioned, scalable internet services. *SOSP 2001*, pp. 230–243.

[12] Hoare, C. A. R. (1978). Communicating sequential processes. *CACM*, 21(8), 666–677.

[13] Milner, R. (1980). *A Calculus of Communicating Systems*. LNCS 92, Springer.

[14] Milner, R., Parrow, J., and Walker, D. (1992). A calculus of mobile processes. *Information and Computation*, 100(1), 1–77.

[15] CNCF CloudEvents (2018). *CloudEvents Specification v1.0*. cloudevents.io.

[16] Tilkov, S. et al. *Self-Contained Systems*. scs-architecture.org.

[17] Brown, S. (2018). *The C4 Model for Software Architecture*. infoq.com.

[18] Lamport, L. (1978). Time, clocks, and the ordering of events in a distributed system. *CACM*, 21(7), 558–565.

[19] Gamma, E., Helm, R., Johnson, R., and Vlissides, J. (1994). *Design Patterns*. Addison-Wesley.

[20] Dey, A. K. (2001). Understanding and using context. *Personal and Ubiquitous Computing*, 5(1), 4–7.

[21] Henricksen, K. and Indulska, J. (2004). A software engineering framework for context-aware pervasive computing. *PerCom 2004*, pp. 77–86.

[22] Brandolini, A. (2013). *Introducing Event Storming*. Leanpub.

[23] Schilit, B. and Theimer, M. (1994). Disseminating active map information to mobile hosts. *IEEE Network*, 8(5), 22–32.

[24] Weiser, M. (1991). The computer for the 21st century. *Scientific American*, 265(3), 94–104.

[25] Coplien, J. O. and Bjørnvig, G. (2010). *Lean Architecture: for Agile Software Development*. Wiley.

[26] Dahan, U. (2012). *Autonomous Components and the Pitfalls of Microservices*. Conference presentations and articles.

[27] Oki, B. M. and Liskov, B. (1988). Viewstamped replication. *PODC 1988*, pp. 8–17.
