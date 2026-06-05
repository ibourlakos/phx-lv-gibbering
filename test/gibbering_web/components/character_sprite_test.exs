defmodule GibberingWeb.Components.CharacterSpriteTest do
  use GibberingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias GibberingWeb.Components.CharacterSprite

  describe "character_sprite/1" do
    test "renders an SVG element" do
      html =
        render_component(&CharacterSprite.character_sprite/1,
          race: "human",
          class_name: "fighter"
        )

      assert html =~ "<svg"
      assert html =~ "viewBox=\"0 0 64 64\""
    end

    test "renders human fighter" do
      html =
        render_component(&CharacterSprite.character_sprite/1,
          race: "human",
          class_name: "fighter"
        )

      assert html =~ "<svg"
    end

    test "renders human wizard" do
      html =
        render_component(&CharacterSprite.character_sprite/1, race: "human", class_name: "wizard")

      assert html =~ "<svg"
    end

    test "renders human rogue" do
      html =
        render_component(&CharacterSprite.character_sprite/1, race: "human", class_name: "rogue")

      assert html =~ "<svg"
    end

    test "renders elf fighter" do
      html =
        render_component(&CharacterSprite.character_sprite/1, race: "elf", class_name: "fighter")

      assert html =~ "<svg"
    end

    test "renders elf wizard" do
      html =
        render_component(&CharacterSprite.character_sprite/1, race: "elf", class_name: "wizard")

      assert html =~ "<svg"
    end

    test "renders elf rogue" do
      html =
        render_component(&CharacterSprite.character_sprite/1, race: "elf", class_name: "rogue")

      assert html =~ "<svg"
    end

    test "renders gnome fighter" do
      html =
        render_component(&CharacterSprite.character_sprite/1,
          race: "gnome",
          class_name: "fighter"
        )

      assert html =~ "<svg"
    end

    test "renders gnome wizard" do
      html =
        render_component(&CharacterSprite.character_sprite/1, race: "gnome", class_name: "wizard")

      assert html =~ "<svg"
    end

    test "renders gnome rogue" do
      html =
        render_component(&CharacterSprite.character_sprite/1, race: "gnome", class_name: "rogue")

      assert html =~ "<svg"
    end

    test "renders a fallback for unknown race/class" do
      html =
        render_component(&CharacterSprite.character_sprite/1,
          race: "orc",
          class_name: "barbarian"
        )

      assert html =~ "<svg"
      assert html =~ "?"
    end

    test "respects the size attribute" do
      html =
        render_component(&CharacterSprite.character_sprite/1,
          race: "human",
          class_name: "fighter",
          size: 128
        )

      assert html =~ "width=\"128\""
      assert html =~ "height=\"128\""
    end
  end
end
