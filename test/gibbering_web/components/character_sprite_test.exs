defmodule GibberingWeb.Components.CharacterSpriteTest do
  use GibberingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias GibberingWeb.Components.CharacterSprite

  @known_sprites [
    {"human", "fighter"},
    {"human", "wizard"},
    {"human", "rogue"},
    {"elf", "fighter"},
    {"elf", "wizard"},
    {"elf", "rogue"},
    {"gnome", "fighter"},
    {"gnome", "wizard"},
    {"gnome", "rogue"}
  ]

  describe "character_sprite/1 — known race/class combinations" do
    for {race, class_name} <- @known_sprites do
      @race race
      @class_name class_name

      test "renders #{@race} #{@class_name} with correct data-sprite" do
        html =
          render_component(&CharacterSprite.character_sprite/1,
            race: @race,
            class_name: @class_name
          )

        assert html =~ ~s(data-sprite="#{@race}_#{@class_name}")
        refute html =~ ~s(>?<)
      end
    end
  end

  describe "character_sprite/1 — fallback" do
    test "renders the fallback sprite for unknown race/class" do
      html =
        render_component(&CharacterSprite.character_sprite/1,
          race: "orc",
          class_name: "barbarian"
        )

      assert html =~ "<svg"
      assert html =~ "?"
    end
  end

  describe "character_sprite/1 — size" do
    test "defaults to 64×64" do
      html =
        render_component(&CharacterSprite.character_sprite/1,
          race: "human",
          class_name: "fighter"
        )

      assert html =~ ~s(width="64")
      assert html =~ ~s(height="64")
    end

    test "respects explicit size attribute" do
      html =
        render_component(&CharacterSprite.character_sprite/1,
          race: "human",
          class_name: "fighter",
          size: 128
        )

      assert html =~ ~s(width="128")
      assert html =~ ~s(height="128")
    end
  end
end
