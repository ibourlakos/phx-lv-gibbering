defmodule Gibbering.Events.Scene.ConditionApplied do
  @current_version 1

  @behaviour Gibbering.Events.Upcaster

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

  @impl Gibbering.Events.Upcaster
  def current_version, do: @current_version

  @impl Gibbering.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
