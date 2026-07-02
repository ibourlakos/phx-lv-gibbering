defmodule GibberingTales.Events.Notification.WhisperDelivered do
  @type t :: %__MODULE__{
          event_id: String.t() | nil,
          campaign_id: pos_integer() | nil,
          target_player_id: pos_integer() | nil,
          text: String.t() | nil,
          sent_at: DateTime.t() | nil
        }

  defstruct [:event_id, :campaign_id, :target_player_id, :text, :sent_at]
end
