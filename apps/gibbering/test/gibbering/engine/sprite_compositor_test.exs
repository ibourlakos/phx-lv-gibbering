defmodule Gibbering.Engine.SpriteCompositorTest do
  use ExUnit.Case, async: true

  alias Gibbering.Engine.SpriteCompositor

  @appearances %{
    {"entity", "warrior", "default"} => %{
      "body_color" => "#4a6fa5",
      "anchor_x" => 0,
      "anchor_y" => 0
    }
  }

  defp entity(overrides \\ []) do
    Map.merge(%{sprite: "warrior", hp: 10, max_hp: 10}, Map.new(overrides))
  end

  describe "compose/3 — body layer" do
    test "renders body with appearance color" do
      result = SpriteCompositor.compose(entity(), @appearances)
      assert result =~ ~s(fill="#4a6fa5")
    end

    test "falls back to gray #7f8c8d for unknown sprite" do
      result = SpriteCompositor.compose(entity(sprite: "unknown"), %{})
      assert result =~ ~s(fill="#7f8c8d")
    end

    test "applies anchor offsets from appearance data" do
      appearances = %{
        {"entity", "warrior", "default"} => %{
          "body_color" => "#fff",
          "anchor_x" => 5,
          "anchor_y" => 8
        }
      }

      result = SpriteCompositor.compose(entity(), appearances)
      assert result =~ ~s(x="5")
      assert result =~ ~s(y="8")
    end
  end

  describe "compose/3 — selection ring" do
    test "no selection ring by default" do
      result = SpriteCompositor.compose(entity(), @appearances)
      refute result =~ "ellipse"
    end

    test "selection ring present when selected: true" do
      result = SpriteCompositor.compose(entity(), @appearances, selected: true)
      assert result =~ "ellipse"
      assert result =~ ~s(stroke="#f0e040")
    end
  end

  describe "compose/3 — HP bar" do
    test "green bar at full HP" do
      result = SpriteCompositor.compose(entity(hp: 10, max_hp: 10), @appearances)
      assert result =~ "#2ecc71"
    end

    test "orange bar at wounded HP (>25%, ≤50%)" do
      result = SpriteCompositor.compose(entity(hp: 4, max_hp: 10), @appearances)
      assert result =~ "#f39c12"
    end

    test "red bar at critical HP (≤25%)" do
      result = SpriteCompositor.compose(entity(hp: 2, max_hp: 10), @appearances)
      assert result =~ "#e74c3c"
    end

    test "bar width proportional to HP fraction" do
      result = SpriteCompositor.compose(entity(hp: 5, max_hp: 10), @appearances)
      assert result =~ ~s(width="28")
    end

    test "bar is positioned above the sprite box top edge" do
      result = SpriteCompositor.compose(entity(), @appearances)
      assert result =~ ~s(y="-9")
    end

    test "no HP bar when show_hp: false" do
      result = SpriteCompositor.compose(entity(), @appearances, show_hp: false)
      refute result =~ "#1f2937"
    end

    test "no HP bar when max_hp is 0" do
      result = SpriteCompositor.compose(entity(hp: 0, max_hp: 0), @appearances)
      refute result =~ "#1f2937"
    end
  end

  describe "compose/3 — show_body opt" do
    test "body omitted when show_body: false" do
      result = SpriteCompositor.compose(entity(), @appearances, show_body: false, show_hp: false)
      refute result =~ "rect"
    end

    test "body included when show_body: true (default)" do
      result = SpriteCompositor.compose(entity(), @appearances, show_hp: false)
      assert result =~ ~s(fill="#4a6fa5")
    end
  end

  describe "compose/3 — two-layer proof-of-concept" do
    test "body + selection ring together" do
      result = SpriteCompositor.compose(entity(), @appearances, selected: true)
      assert result =~ ~s(fill="#4a6fa5")
      assert result =~ "ellipse"
      assert result =~ "#2ecc71"
    end

    test "compose is a pure function — same inputs produce identical output" do
      e = entity(hp: 8, max_hp: 10)

      assert SpriteCompositor.compose(e, @appearances, selected: true) ==
               SpriteCompositor.compose(e, @appearances, selected: true)
    end
  end

  describe "layer_order/0" do
    test "returns the declarative layer list" do
      assert SpriteCompositor.layer_order() == [
               :body,
               :selection_ring,
               :hp_bar,
               :condition_badges
             ]
    end
  end

  describe "compose/3 — condition_badges layer" do
    test "no badges when entity has no conditions and full movement" do
      e = Map.merge(entity(), %{conditions: [], action_economy: %{movement_remaining: 30}})
      result = SpriteCompositor.compose(e, @appearances, show_hp: false, show_body: false)
      refute result =~ "cy=\"38\""
    end

    test "badge rendered for active condition" do
      e = Map.merge(entity(), %{conditions: [:prone], action_economy: %{movement_remaining: 30}})
      result = SpriteCompositor.compose(e, @appearances)
      assert result =~ "<circle"
      assert result =~ "#d97706"
    end

    test "movement_exhausted badge rendered when movement_remaining == 0" do
      e = Map.merge(entity(), %{conditions: [], action_economy: %{movement_remaining: 0}})
      result = SpriteCompositor.compose(e, @appearances)
      assert result =~ "#f97316"
    end
  end
end
