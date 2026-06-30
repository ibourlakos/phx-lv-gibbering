defmodule Gibbering.Events do
  @moduledoc """
  Published Language registry for The Gibbering Engine.

  This namespace is the shared contract between all bounded contexts in the
  polytope. No single context owns it. Every event type that crosses a context
  boundary is defined here.

  Sub-namespaces:

  - `Gibbering.Events.Engine.*`  — generic engine events (movement, turns, HP, resources)
  - `Gibbering.Events.DnD5e.*`  — D&D 5e-specific events (attacks, spells, conditions, items)
  - `Gibbering.Events.Notification.*`  — out-of-band DM/player messages
  - `Gibbering.Events.EventBatch`  — batch envelope carrying a causal event chain

  Infrastructure:

  - `Gibbering.Events.Upcaster`  — behaviour for version migration at read time
  - `Gibbering.Events.Decoder`  — decodes event-log raw maps into typed structs

  See `docs/architecture.md` for the Published Language registry overview and
  `docs/papers/polytope-architecture.md` §3.2, §7, §8.5 for design rationale.
  """
end
