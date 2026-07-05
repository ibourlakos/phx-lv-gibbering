defmodule GibberingEngine.Events.EventBatch do
  @moduledoc """
  Envelope carrying a causally ordered chain of scene events produced by a
  single command. Broadcast atomically on the event bus so subscribers receive
  the full causal chain in one message.

  All events in `events` share the same `correlation_id`. The batch is the unit
  of delivery; the event log stores it as one atomic entry.
  """

  @type t :: %__MODULE__{
          batch_id: String.t(),
          command: atom(),
          correlation_id: String.t(),
          occurred_at: DateTime.t(),
          events: [struct()],
          state_snapshot: struct() | nil
        }

  defstruct [:batch_id, :command, :correlation_id, :occurred_at, :state_snapshot, events: []]
end
