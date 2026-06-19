defmodule Gibbering.Events.Scene.ItemTaken do
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
          actor_id: integer(),
          container_id: integer(),
          instance_id: String.t(),
          item_key: String.t(),
          quantity: pos_integer()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :actor_id,
    :container_id,
    :instance_id,
    :item_key,
    :quantity,
    event_type: :item_taken,
    schema_version: @current_version
  ]

  @impl Gibbering.Events.Upcaster
  def current_version, do: @current_version

  @impl Gibbering.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
