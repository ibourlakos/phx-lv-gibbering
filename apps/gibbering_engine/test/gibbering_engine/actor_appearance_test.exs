defmodule GibberingEngine.ActorAppearanceTest do
  use ExUnit.Case, async: true

  alias GibberingEngine.ActorAppearance

  # --- archetype_for/2 ---

  describe "archetype_for/2" do
    test "resolves wolf to quadruped via static map" do
      assert ActorAppearance.archetype_for("wolf") == :quadruped
    end

    test "resolves rock and chest to structure via static map" do
      assert ActorAppearance.archetype_for("rock") == :structure
      assert ActorAppearance.archetype_for("chest") == :structure
    end

    test "defaults to biped_upright for unknown sprites" do
      assert ActorAppearance.archetype_for("goblin") == :biped_upright
      assert ActorAppearance.archetype_for("human_fighter") == :biped_upright
      assert ActorAppearance.archetype_for("totally_unknown") == :biped_upright
    end

    test "appearance data 'archetype' key overrides static map" do
      assert ActorAppearance.archetype_for("goblin", %{"archetype" => "swarm"}) == :swarm
    end

    test "appearance data archetype overrides static map for wolf too" do
      assert ActorAppearance.archetype_for("wolf", %{"archetype" => "biped_upright"}) ==
               :biped_upright
    end
  end

  # --- canonical_facing/1 ---

  describe "canonical_facing/1" do
    test "west maps to east with flip" do
      assert ActorAppearance.canonical_facing(:west) == {:east, true}
    end

    test "other facings are canonical with no flip" do
      assert ActorAppearance.canonical_facing(:south) == {:south, false}
      assert ActorAppearance.canonical_facing(:north) == {:north, false}
      assert ActorAppearance.canonical_facing(:east) == {:east, false}
    end
  end

  # --- sockets/1 ---

  describe "sockets/1" do
    test "biped_upright has head and hand sockets for south facing" do
      sockets = ActorAppearance.sockets(:biped_upright)
      assert Map.has_key?(sockets, :south)
      assert Map.has_key?(sockets.south, :head)
      assert Map.has_key?(sockets.south, :weapon_hand)
      assert Map.has_key?(sockets.south, :shield_hand)
    end

    test "quadruped has head and tail sockets for east facing" do
      sockets = ActorAppearance.sockets(:quadruped)
      assert Map.has_key?(sockets, :east)
      assert Map.has_key?(sockets.east, :head)
      assert Map.has_key?(sockets.east, :tail)
    end

    test "returns empty map for unknown archetype" do
      assert ActorAppearance.sockets(:unknown_archetype) == %{}
    end
  end

  # --- layer_order/2 ---

  describe "layer_order/2" do
    test "biped_upright south: shield comes after torso (in front)" do
      order = ActorAppearance.layer_order(:biped_upright, :south)
      torso_idx = Enum.find_index(order, &(&1 == :torso))
      shield_idx = Enum.find_index(order, &(&1 == :shield))
      assert torso_idx != nil
      assert shield_idx != nil
      assert shield_idx > torso_idx, "shield should render after (on top of) torso when south"
    end

    test "biped_upright north: shield comes before torso (behind)" do
      order = ActorAppearance.layer_order(:biped_upright, :north)
      torso_idx = Enum.find_index(order, &(&1 == :torso))
      shield_idx = Enum.find_index(order, &(&1 == :shield))
      assert torso_idx != nil
      assert shield_idx != nil
      assert shield_idx < torso_idx, "shield should render before (behind) torso when north"
    end

    test "south and north layer orders differ for biped_upright" do
      south = ActorAppearance.layer_order(:biped_upright, :south)
      north = ActorAppearance.layer_order(:biped_upright, :north)
      refute south == north
    end

    test "falls back to south order for unknown facing" do
      default = ActorAppearance.layer_order(:biped_upright, :southeast)
      south = ActorAppearance.layer_order(:biped_upright, :south)
      assert default == south
    end

    test "returns a list for each defined archetype" do
      for archetype <- [:biped_upright, :quadruped, :swarm, :elemental_amorphous, :structure] do
        result = ActorAppearance.layer_order(archetype, :south)
        assert is_list(result), "expected list for #{archetype}"
        assert length(result) > 0
      end
    end
  end

  # --- render_body/2 ---

  describe "render_body/2" do
    defp make_entity(sprite, opts \\ []) do
      %{
        sprite: sprite,
        facing: Keyword.get(opts, :facing, :south),
        size: Keyword.get(opts, :size, :medium)
      }
    end

    defp appearances_for(sprite, data) do
      %{{"entity", sprite, "default"} => data}
    end

    test "returns a non-empty SVG string for a generic biped" do
      entity = make_entity("goblin")
      result = ActorAppearance.render_body(entity, %{})
      assert is_binary(result)
      assert result != ""
    end

    test "biped south render contains a head circle" do
      entity = make_entity("goblin", facing: :south)
      result = ActorAppearance.render_body(entity, %{})
      assert result =~ "<circle"
    end

    test "biped north render does not show face (no eyes)" do
      entity = make_entity("goblin", facing: :north)
      result = ActorAppearance.render_body(entity, %{})
      refute result =~ ~s(fill="#333")
    end

    test "quadruped (wolf) renders polygon ears" do
      entity = make_entity("wolf", facing: :east)

      appearances =
        appearances_for("wolf", %{"body_color" => "#706050", "archetype" => "quadruped"})

      result = ActorAppearance.render_body(entity, appearances)
      assert result =~ "<polygon"
    end

    test "west facing wraps in scaleX flip transform" do
      entity = make_entity("goblin", facing: :west)
      result = ActorAppearance.render_body(entity, %{})
      assert result =~ ~s[transform="scale(-1,1) translate(-64,0)"]
    end

    test "east facing does not add a flip transform" do
      entity = make_entity("goblin", facing: :east)
      result = ActorAppearance.render_body(entity, %{})
      refute result =~ "scale(-1,1)"
    end

    test "large size wraps in scale(1.5) transform" do
      entity = make_entity("goblin", size: :large)
      result = ActorAppearance.render_body(entity, %{})
      assert result =~ ~s[transform="scale(1.5)"]
    end

    test "medium size has no scale transform" do
      entity = make_entity("goblin", size: :medium)
      result = ActorAppearance.render_body(entity, %{})
      refute result =~ "scale("
    end

    test "uses body_color from appearances" do
      entity = make_entity("goblin")
      appearances = appearances_for("goblin", %{"body_color" => "#ff0000"})
      result = ActorAppearance.render_body(entity, appearances)
      assert result =~ "#ff0000"
    end

    test "entity without :facing field defaults to south" do
      entity = %{sprite: "goblin", size: :medium}
      south_result = ActorAppearance.render_body(entity, %{})
      explicit_south = ActorAppearance.render_body(Map.put(entity, :facing, :south), %{})
      assert south_result == explicit_south
    end

    test "swarm archetype renders circles (dots)" do
      entity = make_entity("rat_swarm")

      appearances =
        appearances_for("rat_swarm", %{"archetype" => "swarm", "body_color" => "#4a3a2a"})

      result = ActorAppearance.render_body(entity, appearances)
      circle_count = result |> String.split("<circle") |> length() |> Kernel.-(1)
      assert circle_count >= 5, "swarm should render multiple dot circles"
    end

    test "structure archetype renders without head circle" do
      entity = make_entity("chest")
      result = ActorAppearance.render_body(entity, %{})
      refute result =~ ~s(fill="#c9a87c")
    end
  end
end
