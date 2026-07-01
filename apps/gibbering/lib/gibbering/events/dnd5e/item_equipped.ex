defmodule Gibbering.Events.DnD5e.ItemEquipped do
  @moduledoc """
  Layer: D&D 5e ruleset.
  Emitted by: SceneServer (via DnD5e ruleset), when an actor equips an item to a slot.
  Signals: actor equipped item_key instance (instance_id) to equipment slot.
  Equipment slots and item keys are D&D 5e inventory concepts.
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
          instance_id: String.t(),
          item_key: String.t(),
          slot: String.t()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :actor_id,
    :instance_id,
    :item_key,
    :slot,
    event_type: :item_equipped,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
