defmodule Gibbering.Rulesets.DnD5e.RuleModifier do
  @moduledoc """
  A data-driven representation of a single D&D 5e rule modifier.

  See docs/predicate-vocabulary.md for the canonical trigger, predicate,
  and effect vocabulary that populates these fields.
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
