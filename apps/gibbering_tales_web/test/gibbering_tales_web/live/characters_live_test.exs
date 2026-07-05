defmodule GibberingTalesWeb.CharactersLiveTest do
  use GibberingTalesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import GibberingTales.AccountsFixtures
  import GibberingTales.CharactersFixtures

  defp mount_characters(conn) do
    user = register_user()
    conn = log_in_user(conn, user)
    {:ok, view, html} = live(conn, "/characters")
    {user, view, html}
  end

  describe "mount" do
    test "renders the characters roster page", %{conn: conn} do
      {_user, _view, html} = mount_characters(conn)
      assert html =~ "My Characters"
    end

    test "shows empty state when the user has no characters", %{conn: conn} do
      {_user, _view, html} = mount_characters(conn)
      assert html =~ "No characters yet"
    end

    test "shows character cards for existing characters", %{conn: conn} do
      user = register_user()
      conn = log_in_user(conn, user)
      create_character(user, %{"name" => "Aerith Thornwood"})

      {:ok, _view, html} = live(conn, "/characters")
      assert html =~ "Aerith Thornwood"
    end

    test "renders character sprite SVG in each card", %{conn: conn} do
      user = register_user()
      conn = log_in_user(conn, user)
      create_character(user)

      {:ok, _view, html} = live(conn, "/characters")
      assert html =~ "viewBox=\"0 0 64 64\""
    end
  end

  describe "new character modal" do
    test "opens the creation modal when New Character is clicked", %{conn: conn} do
      {_user, view, _html} = mount_characters(conn)
      html = view |> element("button", "+ New Character") |> render_click()
      assert html =~ "Identity"
    end

    test "closes the modal when × is clicked", %{conn: conn} do
      {_user, view, _html} = mount_characters(conn)
      view |> element("button", "+ New Character") |> render_click()
      html = view |> element("button[phx-click='close_modal']") |> render_click()
      refute html =~ "Character Name"
    end
  end

  describe "character creation flow" do
    test "shows validation error when name is empty", %{conn: conn} do
      {_user, view, _html} = mount_characters(conn)
      view |> element("button", "+ New Character") |> render_click()

      html =
        view
        |> form("form[phx-submit='step_identity']", %{
          "identity" => %{
            "name" => "",
            "race" => "human",
            "class" => "fighter",
            "level" => "1",
            "alignment" => "true_neutral",
            "background" => ""
          }
        })
        |> render_submit()

      assert html =~ "Name is required"
    end

    test "advances to appearance step with valid identity", %{conn: conn} do
      {_user, view, _html} = mount_characters(conn)
      view |> element("button", "+ New Character") |> render_click()

      html =
        view
        |> form("form[phx-submit='step_identity']", %{
          "identity" => %{
            "name" => "Kira Stonemantle",
            "race" => "gnome",
            "class" => "wizard",
            "level" => "3",
            "alignment" => "neutral_good",
            "background" => "sage"
          }
        })
        |> render_submit()

      assert html =~ "Appearance"
    end

    test "creates a character after completing all steps", %{conn: conn} do
      user = register_user()
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/characters")

      # Identity
      view |> element("button", "+ New Character") |> render_click()

      view
      |> form("form[phx-submit='step_identity']", %{
        "identity" => %{
          "name" => "Bram Hollowreach",
          "race" => "human",
          "class" => "rogue",
          "level" => "1",
          "alignment" => "chaotic_neutral",
          "background" => "criminal"
        }
      })
      |> render_submit()

      # Appearance
      view
      |> form("form[phx-submit='step_appearance']", %{
        "appearance" => %{
          "body_type" => "medium",
          "hair_style" => "short",
          "hair_color" => "black",
          "skin_tone" => "tan",
          "eye_color" => "brown"
        }
      })
      |> render_submit()

      # Scores — standard array assigned in order
      view
      |> form("form[phx-submit='step_scores']", %{
        "scores" => %{
          "strength" => "10",
          "dexterity" => "15",
          "constitution" => "13",
          "intelligence" => "12",
          "wisdom" => "8",
          "charisma" => "14"
        }
      })
      |> render_submit()

      # Proficiencies
      view
      |> form("form[phx-submit='step_proficiencies']", %{
        "proficiencies" => %{
          "skill_choices" => ["stealth", "perception", "deception", "athletics"]
        }
      })
      |> render_submit()

      # Personality
      view
      |> form("form[phx-submit='step_personality']", %{
        "personality" => %{
          "personality_traits" => "Calm",
          "ideals" => "Freedom",
          "bonds" => "My crew",
          "flaws" => "Reckless"
        }
      })
      |> render_submit()

      # Create
      html = view |> element("button[phx-click='create_character']") |> render_click()
      assert html =~ "Bram Hollowreach"
    end
  end

  describe "delete character" do
    test "removes a character from the roster", %{conn: conn} do
      user = register_user()
      conn = log_in_user(conn, user)
      create_character(user, %{"name" => "To Be Deleted"})

      {:ok, view, html} = live(conn, "/characters")
      assert html =~ "To Be Deleted"

      char_id =
        GibberingTales.Characters.list_for_user(user.id) |> hd() |> Map.fetch!(:id)

      html =
        view
        |> element("button[phx-click='delete_character'][phx-value-id='#{char_id}']")
        |> render_click()

      refute html =~ "To Be Deleted"
    end
  end
end
