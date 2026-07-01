defmodule Gibbering.Events.Notification.BroadcastSent do
  @type t :: %__MODULE__{
          event_id: String.t() | nil,
          campaign_id: pos_integer() | nil,
          text: String.t() | nil,
          sent_at: DateTime.t() | nil
        }

  defstruct [:event_id, :campaign_id, :text, :sent_at]
end
