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

  # --- silhouette_for/3 ---

  describe "silhouette_for/3" do
    test "resolves goblinoid sprites" do
      for sprite <- ["goblin", "kobold", "orc", "bugbear"] do
        assert ActorAppearance.silhouette_for(sprite, :biped_upright, %{}) == :goblinoid
      end
    end

    test "resolves undead_gaunt sprites" do
      for sprite <- ["skeleton", "zombie"] do
        assert ActorAppearance.silhouette_for(sprite, :biped_upright, %{}) == :undead_gaunt
      end
    end

    test "resolves giant sprites" do
      for sprite <- ["ogre", "troll"] do
        assert ActorAppearance.silhouette_for(sprite, :biped_upright, %{}) == :giant
      end
    end

    test "defaults to humanoid for unlisted biped_upright sprites" do
      assert ActorAppearance.silhouette_for("human_fighter", :biped_upright, %{}) == :humanoid
      assert ActorAppearance.silhouette_for("guard", :biped_upright, %{}) == :humanoid
    end

    test "appearance data 'silhouette' key overrides the static map" do
      assert ActorAppearance.silhouette_for("goblin", :biped_upright, %{"silhouette" => "giant"}) ==
               :giant
    end

    test "non-biped_upright archetypes always resolve to :default" do
      assert ActorAppearance.silhouette_for("wolf", :quadruped, %{}) == :default
      assert ActorAppearance.silhouette_for("goblin", :swarm, %{"silhouette" => "goblinoid"}) ==
               :default
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
    test "biped_upright layers always start with :shadow" do
      for facing <- [:south, :north, :east] do
        assert hd(ActorAppearance.layer_order(:biped_upright, facing)) == :shadow
      end
    end

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

  # --- render_body/4 ---
  #
  # ActorAppearance is content-agnostic: it resolves archetype/silhouette/facing/layer
  # order and composes whatever `render_layer_fun` returns per layer. These tests use a
  # stub renderer (not GibberingTales.Catalogue.TemplateStore, which lives in a downstream
  # app and would invert the dependency direction) to verify the structural composition:
  # layer ordering, facing/flip, and size scaling.

  describe "render_body/4" do
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

    defp stub_render(style, archetype, silhouette, facing, layer, assigns) do
      "<#{layer} style=#{style} archetype=#{archetype} silhouette=#{silhouette} facing=#{facing} color=#{assigns.color}/>"
    end

    test "concatenates layers in layer_order sequence" do
      entity = make_entity("goblin", facing: :south)
      result = ActorAppearance.render_body(entity, %{}, "dst", &stub_render/6)

      order = ActorAppearance.layer_order(:biped_upright, :south)
      layer_positions = Enum.map(order, &{&1, :binary.match(result, "<#{&1} ") |> elem(0)})

      assert layer_positions == Enum.sort_by(layer_positions, &elem(&1, 1)),
             "layers should appear in layer_order sequence"
    end

    test "resolves goblin to biped_upright/goblinoid and threads them into the callback" do
      entity = make_entity("goblin")
      result = ActorAppearance.render_body(entity, %{}, "dst", &stub_render/6)
      assert result =~ "archetype=biped_upright"
      assert result =~ "silhouette=goblinoid"
    end

    test "west facing wraps in scaleX flip transform, uses east geometry" do
      entity = make_entity("goblin", facing: :west)
      result = ActorAppearance.render_body(entity, %{}, "dst", &stub_render/6)
      assert result =~ ~s[transform="scale(-1,1) translate(-64,0)"]
      assert result =~ "facing=east"
    end

    test "east facing does not add a flip transform" do
      entity = make_entity("goblin", facing: :east)
      result = ActorAppearance.render_body(entity, %{}, "dst", &stub_render/6)
      refute result =~ "scale(-1,1)"
    end

    test "large size wraps in scale(1.5) transform" do
      entity = make_entity("goblin", size: :large)
      result = ActorAppearance.render_body(entity, %{}, "dst", &stub_render/6)
      assert result =~ ~s[transform="scale(1.5)"]
    end

    test "medium size has no scale transform" do
      entity = make_entity("goblin", size: :medium)
      result = ActorAppearance.render_body(entity, %{}, "dst", &stub_render/6)
      refute result =~ "scale("
    end

    test "uses body_color from appearances" do
      entity = make_entity("goblin")
      appearances = appearances_for("goblin", %{"body_color" => "#ff0000"})
      result = ActorAppearance.render_body(entity, appearances, "dst", &stub_render/6)
      assert result =~ "color=#ff0000"
    end

    test "entity without :facing field defaults to south" do
      entity = %{sprite: "goblin", size: :medium}
      south_result = ActorAppearance.render_body(entity, %{}, "dst", &stub_render/6)

      explicit_south =
        ActorAppearance.render_body(Map.put(entity, :facing, :south), %{}, "dst", &stub_render/6)

      assert south_result == explicit_south
    end

    test "passes the requested style_slug through to the callback" do
      entity = make_entity("goblin")
      result = ActorAppearance.render_body(entity, %{}, "carbot", &stub_render/6)
      assert result =~ "style=carbot"
    end

    test "swarm archetype resolves silhouette :default" do
      entity = make_entity("rat_swarm")

      appearances =
        appearances_for("rat_swarm", %{"archetype" => "swarm", "body_color" => "#4a3a2a"})

      result = ActorAppearance.render_body(entity, appearances, "dst", &stub_render/6)
      assert result =~ "archetype=swarm"
      assert result =~ "silhouette=default"
    end
  end
end
