defmodule Gibbering.Events.Scene.EntityMoved do
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
          from: {non_neg_integer(), non_neg_integer()},
          to: {non_neg_integer(), non_neg_integer()},
          cost_ft: non_neg_integer()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :entity_id,
    :entity_name,
    :from,
    :to,
    :cost_ft,
    event_type: :entity_moved,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl Gibbering.Events.Upcaster
  def current_version, do: @current_version

  @impl Gibbering.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
