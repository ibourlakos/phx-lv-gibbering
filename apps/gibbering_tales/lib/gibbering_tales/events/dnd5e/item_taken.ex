defmodule GibberingTales.Events.DnD5e.ItemTaken do
  @moduledoc """
  Layer: D&D 5e ruleset.
  Emitted by: SceneServer (via DnD5e ruleset), when an actor takes an item from a container.
  Signals: actor took quantity of item_key (instance_id) from container_id.
  Item keys, quantities, and container inventory are D&D 5e inventory concepts.
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
    schema_version: @current_version,
    visibility: :public
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
