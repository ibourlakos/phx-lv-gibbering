defmodule Gibbering.Events.Engine.LogEntryHidden do
  @moduledoc """
  Layer: engine (generic — no D&D concepts).
  Emitted by: SceneServer, when the DM hides a previously visible log entry.
  Signals: the event with original_event_id has been demoted to :dm_only visibility;
  player feeds should remove it.
  """

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
          original_event_id: String.t(),
          hidden_at: DateTime.t()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :original_event_id,
    :hidden_at,
    event_type: :log_entry_hidden,
    schema_version: @current_version,
    visibility: :dm_only
  ]

  @impl Gibbering.Events.Upcaster
  def current_version, do: @current_version

  @impl Gibbering.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
