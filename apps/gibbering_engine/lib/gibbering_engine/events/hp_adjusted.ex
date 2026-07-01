defmodule GibberingEngine.Events.HPAdjusted do
  @moduledoc """
  Layer: engine (generic — no D&D concepts).
  Emitted by: SceneServer, whenever an entity's HP changes for any reason.
  Signals: entity HP moved from old_hp to new_hp; reason is a caller-supplied atom
  (e.g. :damage, :healing, :temp_hp). Visibility is dm_only to protect player HP information.
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
          old_hp: integer(),
          new_hp: integer(),
          reason: atom()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :entity_id,
    :entity_name,
    :old_hp,
    :new_hp,
    :reason,
    event_type: :hp_adjusted,
    schema_version: @current_version,
    visibility: :dm_only
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
