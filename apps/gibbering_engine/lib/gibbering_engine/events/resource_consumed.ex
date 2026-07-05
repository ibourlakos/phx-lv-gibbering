defmodule GibberingEngine.Events.ResourceConsumed do
  @moduledoc """
  Layer: engine (generic — no D&D concepts).
  Emitted by: SceneServer, when an entity spends a tracked resource.
  Signals: entity spent amount_used of resource_key; remaining units left after the spend.
  Resource keys are ruleset-defined (e.g. :spell_slots_1, :ki_points).
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
          resource_key: atom(),
          amount_used: pos_integer(),
          remaining: non_neg_integer()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :entity_id,
    :entity_name,
    :resource_key,
    :amount_used,
    :remaining,
    event_type: :resource_consumed,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
