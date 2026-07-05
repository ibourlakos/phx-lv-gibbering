defmodule GibberingTales.Catalogue.TemplateStoreTest do
  use ExUnit.Case, async: true

  alias GibberingTales.Catalogue.TemplateStore

  describe "render/6" do
    test "renders a dst template with the given assigns" do
      result =
        TemplateStore.render("dst", :biped_upright, :humanoid, :south, :torso, %{
          color: "#ff0000"
        })

      assert result =~ "#ff0000"
      assert result =~ "<rect"
    end

    test "renders every seeded archetype/silhouette/facing combination without raising" do
      for silhouette <- [:humanoid, :goblinoid, :undead_gaunt, :giant],
          facing <- [:south, :north, :east],
          layer <- [:shadow, :legs, :torso, :shield, :arms, :head] do
        result =
          TemplateStore.render("dst", :biped_upright, silhouette, facing, layer, %{
            color: "#123456"
          })

        assert is_binary(result)
      end

      for facing <- [:south, :north, :east], layer <- [:shadow, :body, :legs, :head] do
        result = TemplateStore.render("dst", :quadruped, :default, facing, layer, %{color: "#abc"})
        assert is_binary(result)
      end

      for archetype <- [:swarm, :elemental_amorphous, :structure], layer <- [:shadow, :body] do
        result =
          TemplateStore.render("dst", archetype, :default, :south, layer, %{color: "#abc"})

        assert is_binary(result)
      end
    end

    test "falls back to dst when carbot has no template for a combination (shadow)" do
      dst_shadow =
        TemplateStore.render("dst", :biped_upright, :humanoid, :south, :shadow, %{color: "#000"})

      carbot_shadow =
        TemplateStore.render("carbot", :biped_upright, :humanoid, :south, :shadow, %{
          color: "#000"
        })

      assert carbot_shadow == dst_shadow
    end

    test "uses carbot's own template when one exists (torso)" do
      dst_torso =
        TemplateStore.render("dst", :biped_upright, :humanoid, :south, :torso, %{color: "#111"})

      carbot_torso =
        TemplateStore.render("carbot", :biped_upright, :humanoid, :south, :torso, %{
          color: "#111"
        })

      refute carbot_torso == dst_torso
    end

    test "falls back to dst for an unknown style entirely" do
      dst_result =
        TemplateStore.render("dst", :biped_upright, :humanoid, :south, :torso, %{color: "#222"})

      unknown_result =
        TemplateStore.render("nonexistent_style", :biped_upright, :humanoid, :south, :torso, %{
          color: "#222"
        })

      assert unknown_result == dst_result
    end

    test "raises when even dst has no template for the combination" do
      assert_raise RuntimeError, ~r/missing appearance template/, fn ->
        TemplateStore.render("dst", :biped_upright, :humanoid, :south, :nonexistent_layer, %{
          color: "#fff"
        })
      end
    end
  end
end
