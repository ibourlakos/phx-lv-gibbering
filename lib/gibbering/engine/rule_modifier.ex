defmodule Gibbering.Engine.RuleModifier do
  @moduledoc """
  A data-driven representation of a single atomic rule modifier.

  Layer: engine (generic — no D&D concepts).
  This struct is game-agnostic; any ruleset may produce RuleModifier values
  and feed them through its modifier pipeline. The engine itself never
  inspects or constructs RuleModifier structs — only ruleset code does.

  See docs/architecture/predicate-vocabulary.md for the canonical trigger,
  predicate, and effect vocabulary used by the D&D 5e ruleset.
  """

  @enforce_keys [:id, :name, :trigger, :predicate, :effect]
  defstruct [
    :id,
    :name,
    :description,
    :source,
    :trigger,
    :predicate,
    :effect,
    stacking: :additive,
    min_level: 1
  ]

  @type stacking :: :additive | :named_bonus | :binary_flag

  @type t :: %__MODULE__{
          id: atom(),
          name: String.t(),
          description: String.t() | nil,
          source: atom() | nil,
          trigger: term(),
          predicate: term(),
          effect: term(),
          stacking: stacking(),
          min_level: pos_integer()
        }
end
