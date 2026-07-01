defmodule Gibbering.Events.DnD5e.ConditionApplied do
  @moduledoc """
  Layer: D&D 5e ruleset.
  Emitted by: SceneServer (via DnD5e ruleset), when a 5e condition is applied to an entity.
  Signals: condition_id (e.g. :blinded, :prone) was applied to entity from source_id,
  with optional duration in rounds. Conditions are defined in the D&D 5e SRD.
  """

  @current_version 1

  @behaviour GibberingEngine.Events.Upcaster

  @type t :: %__MODULE__{
          event_id: String.t(),
          event_type: atom(),
          schema_version: pos_integer(),
          occurred_at: DateTime.t(),
          correlation_id: String.t(),
          causation_id: String.t(),
          sequence_number: non_neg_integer(),
          visibility: :public | :dm_only | :revealed,
          entity_id: String.t(),
          entity_name: String.t(),
          condition_id: atom(),
          source_id: String.t(),
          duration: non_neg_integer() | nil
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :entity_id,
    :entity_name,
    :condition_id,
    :source_id,
    :duration,
    event_type: :condition_applied,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
