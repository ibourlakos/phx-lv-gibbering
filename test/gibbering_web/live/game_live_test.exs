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

  defp mount_dm_game(conn) do
    user = register_user()
    conn = log_in_user(conn, user)
    game_id = insert_campaign(%{dm_id: user.id})
    Campaigns.join_campaign(game_id, user.id)
    start_supervised!({SceneServer, game_id})
    {:ok, view, _html} = live(conn, "/game/#{game_id}")
    {view, game_id}
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

      view |> element("#entity-#{hero_id}") |> render_click()

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
      view |> element("#entity-#{hero_id}") |> render_click()
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
      view |> element("#entity-#{hero_id}") |> render_click()

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
      view |> element("#entity-#{hero_id}") |> render_click()
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
      view |> element("#entity-#{hero_id}") |> render_click()
      view |> element("[phx-click='end_turn']") |> render_click()

      html = render(view)
      refute html =~ "phx-click=\"move\""
    end
  end

  describe "DM session lifecycle controls" do
    test "DM sees Start button in lobby phase", %{conn: conn} do
      {view, _game_id} = mount_dm_game(conn)
      html = render(view)
      assert html =~ "dm_start"
    end

    test "non-DM does not see DM controls", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      html = render(view)
      refute html =~ "dm_start"
      refute html =~ "dm_pause"
      refute html =~ "dm_resume"
    end

    test "DM can start the session", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      view |> element("[phx-click='dm_start']") |> render_click()
      assert SceneServer.get_state(game_id).phase == :exploration
    end

    test "DM sees Pause and End buttons when session is active", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)
      html = render(view)
      assert html =~ "dm_pause"
      assert html =~ "dm_end_confirm"
    end

    test "DM sees Resume button when paused", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)
      SceneServer.pause_session(game_id)
      html = render(view)
      assert html =~ "dm_resume"
    end

    test "pause overlay shown to all when session is paused", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      SceneServer.ensure_started(game_id)
      SceneServer.start_session(game_id)
      SceneServer.pause_session(game_id)
      html = render(view)
      assert html =~ "SESSION PAUSED"
    end

    test "DM can pause and resume the session", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      view |> element("[phx-click='dm_start']") |> render_click()
      view |> element("[phx-click='dm_pause']") |> render_click()
      assert SceneServer.get_state(game_id).phase == :paused
      html = render(view)
      view |> element("[phx-click='dm_resume']") |> render_click()
      assert SceneServer.get_state(game_id).phase == :exploration
      _ = html
    end

    test "end session confirm button shows confirmation dialog", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)
      html = render(view)
      assert html =~ "dm_end_confirm"
      view |> element("[phx-click='dm_end_confirm']") |> render_click()
      html = render(view)
      assert html =~ "dm_end"
    end

    test "confirming end session sends %EventBatch{SessionEnded} PubSub event", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))
      view |> element("[phx-click='dm_end_confirm']") |> render_click()
      view |> element("[phx-click='dm_end']") |> render_click()

      assert_receive %Gibbering.Events.EventBatch{
                       events: [%Gibbering.Events.Scene.SessionEnded{} | _]
                     },
                     500
    end

    test "%EventBatch{SessionEnded} broadcast redirects all connected clients to dashboard", %{
      conn: conn
    } do
      {view, game_id} = mount_game(conn)
      SceneServer.ensure_started(game_id)

      Phoenix.PubSub.broadcast(
        Gibbering.PubSub,
        SceneServer.topic(game_id),
        %Gibbering.Events.EventBatch{
          events: [%Gibbering.Events.Scene.SessionEnded{campaign_id: game_id}]
        }
      )

      assert_redirect(view, "/dashboard")
    end
  end

  describe "DM initiative panel" do
    test "DM sees initiative list when session is active", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)
      html = render(view)
      assert html =~ "Initiative"
    end

    test "DM can roll initiative for an entity", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view
      |> element("[phx-click='dm_roll_initiative'][phx-value-id='#{hero_id}']")
      |> render_click()

      assert SceneServer.get_state(game_id).initiative_values[hero_id] != nil
    end

    test "DM can add an entity to the turn order", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)
      state = SceneServer.get_state(game_id)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      view
      |> element("[phx-click='dm_add_to_order'][phx-value-id='#{monster_id}']")
      |> render_click()

      assert monster_id in SceneServer.get_state(game_id).turn_order
    end

    test "DM can remove an entity from the turn order", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view
      |> element("[phx-click='dm_remove_from_order'][phx-value-id='#{hero_id}']")
      |> render_click()

      refute hero_id in SceneServer.get_state(game_id).turn_order
    end

    test "DM can move an entry up in the turn order", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)
      state = SceneServer.get_state(game_id)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      # Add monster so there are 2 entries, then move it up
      SceneServer.add_to_turn_order(game_id, monster_id)

      view
      |> element("[phx-click='dm_move_up'][phx-value-id='#{monster_id}']")
      |> render_click()

      assert hd(SceneServer.get_state(game_id).turn_order) == monster_id
    end

    test "DM can force-end the current turn", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.start_session(game_id)

      view |> element("[phx-click='dm_force_end_turn']") |> render_click()

      # Turn was advanced (and wrapped with 1 hero); server still running
      assert %State{} = SceneServer.get_state(game_id)
    end
  end

  describe "handle_info PubSub broadcast" do
    test "%EventBatch{} state_snapshot updates the game board", %{conn: conn} do
      {view, game_id} = mount_combat_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Broadcast a batch with a modified state snapshot — entity renamed.
      renamed = put_in(state.entities[hero_id].name, "BroadcastHero")

      Phoenix.PubSub.broadcast(
        Gibbering.PubSub,
        SceneServer.topic(game_id),
        %Gibbering.Events.EventBatch{state_snapshot: renamed}
      )

      html = render(view)
      assert html =~ "BroadcastHero"
    end
  end

  describe "DM intervention toolset" do
    test "dm_broadcast event sends a broadcast and shows banner to all", %{conn: conn} do
      {view, _game_id} = mount_dm_game(conn)
      view |> element("[phx-click='dm_open_broadcast']") |> render_click()
      view |> element("form[phx-submit='dm_broadcast']") |> render_submit(%{text: "Hello!"})
      assert render(view) =~ "Hello!"
    end

    test "dm_whisper event shows form when triggered", %{conn: conn} do
      {view, _game_id} = mount_dm_game(conn)
      view |> element("[phx-click='dm_open_whisper']") |> render_click()
      assert render(view) =~ "Whisper"
    end

    test "dm_adjust_hp event updates entity HP in state", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      original_hp = state.entities[hero_id].hp

      view
      |> element("#dm-hp-#{hero_id}")
      |> render_submit(%{entity_id: hero_id, delta: "-3"})

      new_hp = SceneServer.get_state(game_id).entities[hero_id].hp
      assert new_hp == max(original_hp - 3, 0)
    end

    test "dm_apply_condition event adds condition to entity", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view
      |> element("#dm-cond-#{hero_id}")
      |> render_submit(%{entity_id: hero_id, condition: "poisoned"})

      assert :poisoned in SceneServer.get_state(game_id).entities[hero_id].conditions
    end

    test "dm_toggle_visibility event hides entity from player view", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view
      |> element("[phx-click='dm_toggle_visibility'][phx-value-id='#{hero_id}']")
      |> render_click()

      assert MapSet.member?(SceneServer.get_state(game_id).hidden_entities, hero_id)
    end

    test "dm_broadcast shows banner on handle_info %BroadcastSent{}", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)

      Phoenix.PubSub.broadcast(
        Gibbering.PubSub,
        SceneServer.notifications_topic(game_id),
        %Gibbering.Events.Notification.BroadcastSent{
          event_id: "evt-test",
          campaign_id: game_id,
          text: "Ambient noise fills the room",
          sent_at: DateTime.utc_now()
        }
      )

      assert render(view) =~ "Ambient noise fills the room"
    end

    test "whisper shows popup on handle_info %WhisperDelivered{} for the current user", %{
      conn: conn
    } do
      {view, game_id} = mount_dm_game(conn)
      user_id = Gibbering.Campaigns.get!(game_id).dm_id

      Phoenix.PubSub.broadcast(
        Gibbering.PubSub,
        SceneServer.notifications_topic(game_id),
        %Gibbering.Events.Notification.WhisperDelivered{
          event_id: "evt-test",
          campaign_id: game_id,
          target_player_id: user_id,
          text: "Secret only for you",
          sent_at: DateTime.utc_now()
        }
      )

      assert render(view) =~ "Secret only for you"
    end
  end

  describe "outcome overlay (issue #143)" do
    defp broadcast_phase(game_id, phase) do
      state = SceneServer.get_state(game_id)

      Phoenix.PubSub.broadcast(
        Gibbering.PubSub,
        SceneServer.topic(game_id),
        %Gibbering.Events.EventBatch{state_snapshot: %{state | phase: phase}}
      )
    end

    test "victory overlay renders for all clients when phase is :victory", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      broadcast_phase(game_id, :victory)
      assert render(view) =~ "Victory!"
    end

    test "defeat overlay renders for all clients when phase is :defeat", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      broadcast_phase(game_id, :defeat)
      assert render(view) =~ "Defeat"
    end

    test "DM sees Return to Lobby button in the outcome overlay", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      broadcast_phase(game_id, :victory)
      assert render(view) =~ "dm_return_to_lobby"
    end

    test "non-DM does not see Return to Lobby button", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      broadcast_phase(game_id, :victory)
      refute render(view) =~ "dm_return_to_lobby"
    end

    test "dm_return_to_lobby transitions phase back to :lobby", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      SceneServer.force_transition_phase(game_id, :victory)
      broadcast_phase(game_id, :victory)
      view |> element("[phx-click='dm_return_to_lobby']") |> render_click()
      assert SceneServer.get_state(game_id).phase == :lobby
    end

    test "outcome overlay is absent in lobby phase", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      html = render(view)
      refute html =~ "Victory!"
      refute html =~ "Defeat"
    end
  end

  describe "container panel (issue #127)" do
    defp insert_adjacent_chest(game_id, items \\ []) do
      chest =
        Repo.insert!(%Entity{
          name: "Treasure Chest",
          type: "object",
          sprite: "chest",
          x: 3,
          y: 2,
          hp: 1,
          max_hp: 1,
          tags: [],
          stats: %{"object_subtype" => "loot_source", "items" => items},
          campaign_id: game_id
        })

      SceneServer.reload_entities(game_id)
      chest
    end

    test "container panel is hidden when no container is open", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      refute render(view) =~ "container-panel"
    end

    test "container panel appears after open_container succeeds", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      chest = insert_adjacent_chest(game_id, [])

      SceneServer.open_container(game_id, chest.id)

      html = render(view)
      assert html =~ "container-panel"
      assert html =~ "Treasure Chest"
    end

    test "item names appear in the panel", %{conn: conn} do
      {view, game_id} = mount_game(conn)

      items = [
        %{"instance_id" => "x1", "item_key" => "dagger", "quantity" => 2, "is_magical" => false}
      ]

      chest = insert_adjacent_chest(game_id, items)
      SceneServer.open_container(game_id, chest.id)

      html = render(view)
      assert html =~ "Dagger"
    end

    test "take_all event removes all items and closes the panel", %{conn: conn} do
      {view, game_id} = mount_game(conn)

      items = [
        %{"instance_id" => "x1", "item_key" => "dagger", "quantity" => 1, "is_magical" => false}
      ]

      chest = insert_adjacent_chest(game_id, items)
      SceneServer.open_container(game_id, chest.id)

      view |> element("[phx-click='take_all']") |> render_click()

      refute render(view) =~ "container-panel"
    end

    test "close_container event hides the panel", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      chest = insert_adjacent_chest(game_id, [])
      SceneServer.open_container(game_id, chest.id)

      view |> element("[phx-click='close_container']") |> render_click()

      refute render(view) =~ "container-panel"
    end
  end
end
