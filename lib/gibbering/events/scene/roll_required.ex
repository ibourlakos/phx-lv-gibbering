defmodule Gibbering.Events.Scene.RollRequired do
  @current_version 1

  @behaviour Gibbering.Events.Upcaster

  @type roll_type :: :attack | :damage | :saving_throw | :ability_check | :initiative

  @type t :: %__MODULE__{
          event_id: String.t(),
          event_type: atom(),
          schema_version: pos_integer(),
          occurred_at: DateTime.t(),
          correlation_id: String.t(),
          causation_id: String.t(),
          sequence_number: non_neg_integer(),
          entity_id: integer(),
          roll_type: roll_type(),
          dice_expression: String.t(),
          context_label: String.t()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :entity_id,
    :roll_type,
    :dice_expression,
    :context_label,
    event_type: :roll_required,
    schema_version: @current_version
  ]

  @impl Gibbering.Events.Upcaster
  def current_version, do: @current_version

  @impl Gibbering.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
