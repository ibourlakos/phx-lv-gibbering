defmodule Gibbering.Engine.ConditionBadgeTest do
  use ExUnit.Case, async: true

  alias Gibbering.Engine.ConditionBadge

  defp entity(overrides \\ []) do
    Map.merge(
      %{conditions: [], action_economy: %{movement_remaining: 30}},
      Map.new(overrides)
    )
  end

  describe "effective_conditions/1" do
    test "returns real conditions when movement_remaining > 0" do
      e = entity(conditions: [:prone, :grappled])
      assert ConditionBadge.effective_conditions(e) == [:prone, :grappled]
    end

    test "prepends movement_exhausted when movement_remaining == 0" do
      e = entity(conditions: [:prone], action_economy: %{movement_remaining: 0})
      assert ConditionBadge.effective_conditions(e) == [:movement_exhausted, :prone]
    end

    test "does not add movement_exhausted when movement_remaining > 0" do
      e = entity(action_economy: %{movement_remaining: 5})
      refute :movement_exhausted in ConditionBadge.effective_conditions(e)
    end

    test "returns [] when no conditions and movement_remaining > 0" do
      assert ConditionBadge.effective_conditions(entity()) == []
    end

    test "handles missing action_economy gracefully" do
      e = %{conditions: [:stunned]}
      assert ConditionBadge.effective_conditions(e) == [:stunned]
    end

    test "handles missing conditions key gracefully" do
      e = %{action_economy: %{movement_remaining: 0}}
      assert ConditionBadge.effective_conditions(e) == [:movement_exhausted]
    end
  end

  describe "render_badges/1" do
    test "returns empty string when no conditions and movement > 0" do
      assert ConditionBadge.render_badges(entity()) == ""
    end

    test "renders a circle per visible condition" do
      e = entity(conditions: [:prone])
      svg = ConditionBadge.render_badges(e)
      assert svg =~ "<circle"
    end

    test "movement_exhausted badge rendered when movement_remaining == 0" do
      e = entity(action_economy: %{movement_remaining: 0})
      svg = ConditionBadge.render_badges(e)
      # orange color for movement_exhausted
      assert svg =~ "#f97316"
    end

    test "prone uses amber color and down-chevron path" do
      e = entity(conditions: [:prone])
      svg = ConditionBadge.render_badges(e)
      assert svg =~ "#d97706"
      assert svg =~ "<path"
    end

    test "grappled uses red color and interlocked circles" do
      e = entity(conditions: [:grappled])
      svg = ConditionBadge.render_badges(e)
      assert svg =~ "#ef4444"
      # two circles for the icon
      assert svg =~ ~s(fill="none" stroke="white")
    end

    test "movement_exhausted icon is a horizontal bar rect" do
      e = entity(action_economy: %{movement_remaining: 0})
      svg = ConditionBadge.render_badges(e)
      assert svg =~ "<rect"
    end

    test "up to 3 conditions rendered without overflow" do
      e = entity(conditions: [:prone, :grappled, :poisoned])
      svg = ConditionBadge.render_badges(e)
      refute svg =~ "+1"
      refute svg =~ "+2"
    end

    test "4th condition collapses into +1 overflow badge" do
      e = entity(conditions: [:prone, :grappled, :poisoned, :stunned])
      svg = ConditionBadge.render_badges(e)
      assert svg =~ "+1"
    end

    test "5 conditions collapses extra two into +2 overflow" do
      e = entity(conditions: [:prone, :grappled, :poisoned, :stunned, :blinded])
      svg = ConditionBadge.render_badges(e)
      assert svg =~ "+2"
    end

    test "badges are positioned at y=34" do
      e = entity(conditions: [:prone])
      svg = ConditionBadge.render_badges(e)
      assert svg =~ "cy=\"38\""
    end

    test "second badge is offset by 10px in x" do
      e = entity(conditions: [:prone, :grappled])
      svg = ConditionBadge.render_badges(e)
      # first badge center: cx=4, second: cx=14
      assert svg =~ ~s(cx="4")
      assert svg =~ ~s(cx="14")
    end

    test "unknown condition renders first-letter fallback text" do
      e = entity(conditions: [:charmed])
      svg = ConditionBadge.render_badges(e)
      assert svg =~ ">C<"
    end
  end
end
