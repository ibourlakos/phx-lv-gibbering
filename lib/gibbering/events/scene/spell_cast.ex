defmodule Gibbering.Events.Scene.SpellCast do
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
          caster_id: String.t(),
          caster_name: String.t(),
          spell_key: atom(),
          target_id: String.t() | nil,
          target_name: String.t() | nil,
          outcome: atom()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :caster_id,
    :caster_name,
    :spell_key,
    :target_id,
    :target_name,
    :outcome,
    event_type: :spell_cast,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl Gibbering.Events.Upcaster
  def current_version, do: @current_version

  @impl Gibbering.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
