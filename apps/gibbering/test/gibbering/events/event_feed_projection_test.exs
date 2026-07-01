defmodule Gibbering.Events.EventFeedProjectionTest do
  use ExUnit.Case, async: true

  alias Gibbering.Events.EventFeedProjection
  alias GibberingEngine.Events.{LogEntryHidden, LogEntryRevealed}
  alias GibberingTales.Events.DnD5e.{AttackResolved, DamageDealt}

  defp attack(id, visibility \\ :public) do
    %AttackResolved{
      event_id: id,
      attacker_id: "1",
      attacker_name: "Aldric",
      target_id: "2",
      target_name: "Goblin",
      roll: 12,
      hit?: true,
      visibility: visibility
    }
  end

  defp damage(id, visibility \\ :public) do
    %DamageDealt{
      event_id: id,
      target_id: "2",
      target_name: "Goblin",
      amount: 8,
      damage_type: :slashing,
      new_hp: 4,
      visibility: visibility
    }
  end

  defp reveal(original_id) do
    %LogEntryRevealed{
      event_id: Ecto.UUID.generate(),
      original_event_id: original_id,
      revealed_at: DateTime.utc_now()
    }
  end

  defp hide(original_id) do
    %LogEntryHidden{
      event_id: Ecto.UUID.generate(),
      original_event_id: original_id,
      hidden_at: DateTime.utc_now()
    }
  end

  describe "fold/1" do
    test "empty log returns empty overrides" do
      assert EventFeedProjection.fold([]) == %{}
    end

    test "non-control events are ignored" do
      events = [attack("a1"), damage("d1")]
      assert EventFeedProjection.fold(events) == %{}
    end

    test "LogEntryRevealed marks event as :revealed" do
      events = [attack("a1", :dm_only), reveal("a1")]
      assert EventFeedProjection.fold(events) == %{"a1" => :revealed}
    end

    test "LogEntryHidden after reveal reverts to :dm_only" do
      events = [attack("a1", :dm_only), reveal("a1"), hide("a1")]
      assert EventFeedProjection.fold(events) == %{"a1" => :dm_only}
    end

    test "re-reveal after hide restores :revealed" do
      events = [attack("a1", :dm_only), reveal("a1"), hide("a1"), reveal("a1")]
      assert EventFeedProjection.fold(events) == %{"a1" => :revealed}
    end

    test "multiple events overridden independently" do
      events = [attack("a1", :dm_only), damage("d1", :dm_only), reveal("a1")]
      overrides = EventFeedProjection.fold(events)
      assert overrides["a1"] == :revealed
      assert Map.get(overrides, "d1") == nil
    end
  end

  describe "effective_visibility/2" do
    test "returns struct visibility when no override" do
      event = attack("a1", :public)
      assert EventFeedProjection.effective_visibility(event, %{}) == :public
    end

    test "returns override when present" do
      event = attack("a1", :dm_only)
      overrides = %{"a1" => :revealed}
      assert EventFeedProjection.effective_visibility(event, overrides) == :revealed
    end
  end

  describe "player_visible/1" do
    test "returns :public events as-is" do
      events = [attack("a1", :public), damage("d1", :public)]
      visible = EventFeedProjection.player_visible(events)
      assert length(visible) == 2
      assert {%AttackResolved{event_id: "a1"}, :public} = hd(visible)
    end

    test "excludes :dm_only events by default" do
      events = [attack("a1", :dm_only), damage("d1", :public)]
      visible = EventFeedProjection.player_visible(events)
      assert length(visible) == 1
      assert {%DamageDealt{event_id: "d1"}, :public} = hd(visible)
    end

    test "includes :dm_only event after LogEntryRevealed with :revealed visibility" do
      events = [attack("a1", :dm_only), damage("d1", :public), reveal("a1")]
      visible = EventFeedProjection.player_visible(events)
      assert length(visible) == 2
      assert Enum.any?(visible, fn {e, vis} -> e.event_id == "a1" and vis == :revealed end)
    end

    test "excludes previously revealed event after LogEntryHidden" do
      events = [attack("a1", :dm_only), reveal("a1"), hide("a1")]
      visible = EventFeedProjection.player_visible(events)
      assert Enum.empty?(visible)
    end

    test "LogEntryRevealed and LogEntryHidden events themselves are excluded" do
      events = [attack("a1", :dm_only), reveal("a1")]
      visible = EventFeedProjection.player_visible(events)
      assert Enum.all?(visible, fn {e, _} -> not match?(%LogEntryRevealed{}, e) end)
    end

    test "re-revealed event appears after second reveal" do
      events = [attack("a1", :dm_only), reveal("a1"), hide("a1"), reveal("a1")]
      visible = EventFeedProjection.player_visible(events)
      assert Enum.any?(visible, fn {e, vis} -> e.event_id == "a1" and vis == :revealed end)
    end
  end
end
