defmodule Gibbering.Events.Engine.LogEntryRevealed do
  @moduledoc """
  Layer: engine (generic — no D&D concepts).
  Emitted by: SceneServer, when the DM reveals a previously dm_only log entry.
  Signals: the event with original_event_id has been promoted to :revealed visibility;
  player feeds should now include it.
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
          revealed_at: DateTime.t()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :original_event_id,
    :revealed_at,
    event_type: :log_entry_revealed,
    schema_version: @current_version,
    visibility: :dm_only
  ]

  @impl Gibbering.Events.Upcaster
  def current_version, do: @current_version

  @impl Gibbering.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
