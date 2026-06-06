defmodule GibberingWeb.GameLiveTest do
  # Full-stack: mounts a real LiveView, drives events, asserts rendered output.
  # Requires the DB (loads Campaign). async: false because SceneServer is shared state.
  use GibberingWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Gibbering.GameFixtures
  import Gibbering.AccountsFixtures

  alias Gibbering.{Campaigns, Repo, Entity}
  alias Gibbering.Engine.{SceneServer, State}

  defp mount_game(conn) do
    user = register_user()
    conn = log_in_user(conn, user)
    game_id = insert_campaign()
    Campaigns.join_campaign(game_id, user.id)
    # Pre-start the server so the LiveView mounts against an already-running game.
    start_supervised!({SceneServer, game_id})
    {:ok, view, _html} = live(conn, "/game/#{game_id}")
    {view, game_id}
  end

  # A combat-ready campaign: hero at (1,1) with weapon + spell, monster at (2,1).
  # Chebyshev distance = 1 — hero can attack or cast at the monster immediately.
  defp insert_combat_campaign do
    game_id = insert_campaign()

    Repo.delete_all(Entity)

    Repo.insert!(%Entity{
      name: "Test Fighter",
      type: "hero",
      sprite: "human_fighter",
      race: "human",
      class: "fighter",
      x: 1,
      y: 1,
      hp: 20,
      max_hp: 20,
      level: 3,
      tags: [],
      stats: %{
        "speed" => 30,
        "strength" => 16,
        "dexterity" => 12,
        "constitution" => 14,
        "intelligence" => 10,
        "wisdom" => 10,
        "charisma" => 10,
        "spells" => ["fire_bolt"],
        "equipped_weapon" => %{
          "key" => "longsword",
          "damage_dice" => "1d8",
          "damage_type" => "slashing",
          "attack_ability" => "strength",
          "properties" => []
        },
        "equipped_armor" => %{
          "key" => "chain_mail",
          "base_ac" => 16,
          "armor_category" => "heavy"
        }
      },
      campaign_id: game_id
    })

    Repo.insert!(%Entity{
      name: "Test Goblin",
      type: "monster",
      sprite: "goblin",
      x: 2,
      y: 1,
      hp: 10,
      max_hp: 10,
      level: 1,
      tags: [],
      stats: %{"speed" => 30},
      campaign_id: game_id
    })

    game_id
  end

  defp mount_combat_game(conn) do
    user = register_user()
    conn = log_in_user(conn, user)
    game_id = insert_combat_campaign()
    Campaigns.join_campaign(game_id, user.id)
    start_supervised!({SceneServer, game_id})
    {:ok, view, _html} = live(conn, "/game/#{game_id}")
    {view, game_id}
  end

  describe "mount" do
    test "renders the SVG game board", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      html = render(view)
      assert html =~ "<svg"
    end

    test "renders isometric polygon tiles for each map cell", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      html = render(view)
      # 5x5 grid = 25 tile polygons; move overlays add more when active.
      polygon_count = html |> String.split("<polygon") |> length() |> Kernel.-(1)
      assert polygon_count >= 25
    end
  end

  describe "select_entity event" do
    test "clicking the active hero highlights valid move tiles", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view |> element("[phx-click='select_entity'][phx-value-id='#{hero_id}']") |> render_click()

      html = render(view)
      # Move overlay tiles carry phx-click="move" — their presence means moves were rendered.
      assert html =~ "phx-click=\"move\""
    end
  end

  describe "move event" do
    test "moving the hero clears the move overlay", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Select hero to show move tiles, then click a specific reachable tile.
      view |> element("[phx-click='select_entity'][phx-value-id='#{hero_id}']") |> render_click()
      view |> element("[phx-click='move'][phx-value-x='0'][phx-value-y='0']") |> render_click()

      html = render(view)
      refute html =~ "phx-click=\"move\""
    end
  end

  describe "attack event" do
    test "attacking the adjacent monster adds a log entry", %{conn: conn} do
      {view, game_id} = mount_combat_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Select hero → valid_targets will include the adjacent goblin.
      view |> element("[phx-click='select_entity'][phx-value-id='#{hero_id}']") |> render_click()

      # The goblin entity element now renders phx-click="attack" because it is in valid_targets.
      view |> element("[phx-click='attack']") |> render_click()

      html = render(view)
      # Log shows either a damage hit or "destroyed!" entry.
      assert html =~ "Test Fighter" and (html =~ "hits" or html =~ "destroyed")
    end
  end

  describe "select_spell event" do
    test "selecting a spell marks it active and shows spell targets", %{conn: conn} do
      {view, _game_id} = mount_combat_game(conn)

      # The spell panel renders because the active hero has stats["spells"].
      view |> element("[phx-click='select_spell'][phx-value-key='fire_bolt']") |> render_click()

      html = render(view)
      # The selected spell button gets the bg-purple-700 class.
      assert html =~ "bg-purple-700"
    end
  end

  describe "cast_spell event" do
    test "casting a spell on a target adds a log entry", %{conn: conn} do
      {view, game_id} = mount_combat_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Select hero, then select a spell; the goblin entity becomes a spell target.
      view |> element("[phx-click='select_entity'][phx-value-id='#{hero_id}']") |> render_click()
      view |> element("[phx-click='select_spell'][phx-value-key='fire_bolt']") |> render_click()
      view |> element("[phx-click='cast_spell']") |> render_click()

      html = render(view)
      assert html =~ "fire_bolt" or html =~ "Fire Bolt"
    end
  end

  describe "end_turn event" do
    test "end_turn button clears move overlays", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Select hero to show moves, then end turn.
      view |> element("[phx-click='select_entity'][phx-value-id='#{hero_id}']") |> render_click()
      view |> element("[phx-click='end_turn']") |> render_click()

      html = render(view)
      refute html =~ "phx-click=\"move\""
    end
  end

  describe "handle_info PubSub broadcast" do
    test "state_updated broadcast updates the game board", %{conn: conn} do
      {view, game_id} = mount_combat_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Broadcast a modified state with a renamed entity directly via PubSub.
      renamed = put_in(state.entities[hero_id].name, "BroadcastHero")

      Phoenix.PubSub.broadcast(
        Gibbering.PubSub,
        SceneServer.topic(game_id),
        {:state_updated, renamed}
      )

      html = render(view)
      assert html =~ "BroadcastHero"
    end
  end
end
