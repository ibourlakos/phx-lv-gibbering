defmodule GibberingEngine.Events.SessionEnded do
  @moduledoc """
  Layer: engine (generic — no D&D concepts).
  Emitted by: SceneServer, when the DM ends the session.
  Signals: the game session for campaign_id has terminated; all subscribers should
  clean up and redirect to the post-session view.
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
          campaign_id: String.t()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :campaign_id,
    event_type: :session_ended,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
