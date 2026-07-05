defmodule GibberingEngine.Events.ContainerOpened do
  @moduledoc """
  Layer: engine (generic — no D&D concepts).
  Emitted by: SceneServer, when an actor opens a container entity.
  Signals: actor_id opened container_id; the container's inventory is now accessible to the actor.
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
          container_id: integer()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :actor_id,
    :container_id,
    event_type: :container_opened,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
