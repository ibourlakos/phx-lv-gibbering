defmodule Gibbering.Events.Scene.TurnAdvanced do
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
          from_entity_id: String.t(),
          from_entity_name: String.t(),
          to_entity_id: String.t(),
          to_entity_name: String.t(),
          round_number: pos_integer()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :from_entity_id,
    :from_entity_name,
    :to_entity_id,
    :to_entity_name,
    :round_number,
    event_type: :turn_advanced,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl Gibbering.Events.Upcaster
  def current_version, do: @current_version

  @impl Gibbering.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
