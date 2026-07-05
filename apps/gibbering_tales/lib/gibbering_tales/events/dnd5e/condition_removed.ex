defmodule GibberingTales.Events.DnD5e.ConditionRemoved do
  @moduledoc """
  Layer: D&D 5e ruleset.
  Emitted by: SceneServer (via DnD5e ruleset), when a 5e condition is removed from an entity.
  Signals: condition_id was removed from entity; reason is a ruleset atom
  (e.g. :duration_expired, :dispelled, :saving_throw_success).
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
    :condition_id,
    :reason,
    event_type: :condition_removed,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
