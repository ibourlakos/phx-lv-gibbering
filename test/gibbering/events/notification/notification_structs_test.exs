defmodule Gibbering.Events.Notification.NotificationStructsTest do
  use ExUnit.Case, async: true

  alias Gibbering.Events.Notification.{BroadcastSent, WhisperDelivered}

  describe "BroadcastSent" do
    test "can be constructed with all fields" do
      now = DateTime.utc_now()

      s = %BroadcastSent{
        event_id: "evt-1",
        campaign_id: 42,
        text: "Hello players!",
        sent_at: now
      }

      assert s.event_id == "evt-1"
      assert s.campaign_id == 42
      assert s.text == "Hello players!"
      assert s.sent_at == now
    end

    test "all fields default to nil" do
      s = %BroadcastSent{}
      assert s.event_id == nil
      assert s.campaign_id == nil
      assert s.text == nil
      assert s.sent_at == nil
    end
  end

  describe "WhisperDelivered" do
    test "can be constructed with all fields" do
      now = DateTime.utc_now()

      s = %WhisperDelivered{
        event_id: "evt-2",
        campaign_id: 42,
        target_player_id: 7,
        text: "Secret only for you",
        sent_at: now
      }

      assert s.event_id == "evt-2"
      assert s.campaign_id == 42
      assert s.target_player_id == 7
      assert s.text == "Secret only for you"
      assert s.sent_at == now
    end

    test "all fields default to nil" do
      s = %WhisperDelivered{}
      assert s.event_id == nil
      assert s.campaign_id == nil
      assert s.target_player_id == nil
      assert s.text == nil
      assert s.sent_at == nil
    end
  end
end
