defmodule Gibbering.Ruleset do
  @moduledoc """
  Behaviour that all ruleset modules must implement.

  A ruleset is a compile-time module reference stored in `Engine.State.ruleset`.
  SceneServer delegates all rule decisions to the active ruleset, making the
  engine ruleset-swappable without changes to the engine core.

  Decision (#14): `behaviour` over `protocol` — rulesets are whole-module
  strategies, not per-value polymorphism; behaviour dispatch is direct and idiomatic.
  """

  @doc """
  Collects all `RuleModifier` structs applicable to an action.
  `entity` is the acting entity map, `action` is an atom (:attack, :move, etc.),
  `state` is the current `Engine.State`.
  """
  @callback collect_modifiers(entity :: map(), action :: atom(), state :: term()) :: [term()]

  @doc """
  Returns the initial resource pool map for a newly instantiated entity.
  Resource pools include spell slots, ki points, rage charges, etc.
  """
  @callback initial_resources(entity :: map()) :: %{optional(atom()) => term()}

  @doc """
  Returns the initial action economy map for an entity at the start of a turn.
  Typical D&D 5e: `%{action: 1, bonus_action: 1, reaction: 1, movement: speed}`.
  """
  @callback initial_action_economy(entity :: map()) :: %{optional(atom()) => term()}

  @doc """
  Applies end-of-turn effects to a single entity: resets spent action economy,
  ticks conditions, etc. Called by SceneServer during `advance_turn`.
  Returns the updated entity map.
  """
  @callback advance_turn(entity :: map()) :: map()

  @doc """
  Applies short-rest recovery to a single entity.
  Restores resources that recharge on a short rest (e.g. Fighter Second Wind, Warlock pact slots).
  Returns the updated entity map.
  """
  @callback short_rest_entity(entity :: map()) :: map()

  @doc """
  Applies long-rest recovery to a single entity.
  Restores all spell slots and class resources.
  Returns the updated entity map.
  """
  @callback long_rest_entity(entity :: map()) :: map()

  @typedoc """
  A single action button to render in the player action bar.
  `event` is the phx-click event name; `value` is the phx-value map;
  `sublabel` is optional secondary text (e.g. spell level).
  """
  @type action_button :: %{
          required(:label) => String.t(),
          required(:event) => String.t(),
          required(:value) => %{String.t() => String.t()},
          optional(:sublabel) => String.t() | nil
        }

  @doc """
  Returns the list of action buttons to render in the action bar for the
  currently active entity. Called with the active entity and current state.
  Returns `[]` when the entity has no ruleset-specific actions available.
  """
  @callback action_buttons(entity :: map(), state :: term()) :: [action_button()]

  @doc """
  Returns the list of condition options available for the DM condition picker.
  Each entry is `{condition_id :: atom(), label :: String.t()}`.
  """
  @callback available_conditions() :: [{atom(), String.t()}]

  @doc """
  Returns an initialized ruleset state term for a new scene.
  Stored as `Engine.State.ruleset_state`; the engine treats it as an opaque term.
  """
  @callback init_ruleset_state() :: term()
end
