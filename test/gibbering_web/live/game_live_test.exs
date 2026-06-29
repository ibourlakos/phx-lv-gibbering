defmodule GibberingWeb.GameLiveTest do
  # Full-stack: mounts a real LiveView, drives events, asserts rendered output.
  # Requires the DB (loads Campaign). async: false because SceneServer is shared state.
  use GibberingWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Gibbering.GameFixtures
  import Gibbering.AccountsFixtures
  import Gibbering.CharactersFixtures

  import Ecto.Query, only: [from: 2]

  alias Gibbering.{Campaigns, CampaignCharacters, Repo, Entity, GameMap, GridTile}
  alias Gibbering.Catalogue.EntityPreset
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

    test "active turn indicator is absent in lobby phase", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      html = render(view)
      # Yellow ellipse (SpriteCompositor selection_ring) must not appear before combat starts.
      refute html =~ ~s(stroke="#f0e040")
      # Yellow dashed polygon (template active-turn ring) must also be absent.
      refute html =~ ~s(stroke="#f1c40f")
    end

    test "active turn indicator appears in in_combat phase", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      SceneServer.force_transition_phase(game_id, :in_combat)
      html = render(view)
      assert html =~ ~s(stroke="#f0e040")
    end
  end

  describe "select_entity event" do
    test "clicking the active hero does not show move overlay until Move button is clicked", %{
      conn: conn
    } do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view |> element("#entity-#{hero_id}") |> render_click()

      html = render(view)
      # Move overlay only appears after explicit activate_move, not on entity select.
      refute html =~ "phx-click=\"move\""
    end
  end

  describe "move event" do
    test "activating move then clicking a tile refreshes overlay while movement remains", %{
      conn: conn
    } do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Select hero → activate move → overlay appears.
      view |> element("#entity-#{hero_id}") |> render_click()
      view |> element("[phx-click='activate_move']") |> render_click()

      assert render(view) =~ "phx-click=\"move\""

      # Move one tile — hero has 30ft speed so 25ft remains. Overlay should refresh.
      view |> element("[phx-click='move'][phx-value-x='0'][phx-value-y='0']") |> render_click()

      html = render(view)
      assert html =~ "phx-click=\"move\""
    end
  end

  describe "attack event" do
    test "attacking the adjacent monster resolves the attack", %{conn: conn} do
      {view, game_id} = mount_combat_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      monster_id = Enum.find_value(state.entities, fn {id, e} -> e.type == "monster" && id end)

      # Select hero → valid_targets will include the adjacent goblin.
      view |> element("#entity-#{hero_id}") |> render_click()

      # The goblin entity element now renders phx-click="attack" because it is in valid_targets.
      view |> element("[phx-click='attack']") |> render_click()

      # Attack resolves synchronously via SceneServer: monster either took damage or was destroyed.
      state_after = SceneServer.get_state(game_id)

      assert state_after.entities[monster_id] == nil or
               state_after.entities[monster_id].hp < state.entities[monster_id].hp
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
    test "end_turn button clears any active move overlay", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Activate move overlay, then end turn — overlay must be cleared.
      view |> element("#entity-#{hero_id}") |> render_click()
      view |> element("[phx-click='activate_move']") |> render_click()
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

      view |> element("[phx-click='switch_tab'][phx-value-tab='dm']") |> render_click()

      view
      |> element("[phx-click='open_dm_intervene'][phx-value-id='#{hero_id}']")
      |> render_click()

      view
      |> element("#intervene-hp-#{hero_id}")
      |> render_submit(%{entity_id: hero_id, delta: "-3"})

      new_hp = SceneServer.get_state(game_id).entities[hero_id].hp
      assert new_hp == max(original_hp - 3, 0)
    end

    test "dm_apply_condition event adds condition to entity", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view |> element("[phx-click='switch_tab'][phx-value-tab='dm']") |> render_click()

      view
      |> element("[phx-click='open_dm_intervene'][phx-value-id='#{hero_id}']")
      |> render_click()

      view
      |> element("#intervene-cond-#{hero_id}")
      |> render_submit(%{entity_id: hero_id, condition: "poisoned"})

      assert :poisoned in SceneServer.get_state(game_id).entities[hero_id].conditions
    end

    test "dm_toggle_visibility event hides entity from player view", %{conn: conn} do
      {view, game_id} = mount_dm_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view |> element("[phx-click='switch_tab'][phx-value-tab='dm']") |> render_click()

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

  # Mounts as a player with an active CampaignCharacter (for #145 auto-roll tests).
  defp mount_player_game(conn) do
    player = register_user()
    conn = log_in_user(conn, player)
    game_id = insert_campaign()
    Campaigns.join_campaign(game_id, player.id)
    start_supervised!({SceneServer, game_id})
    character = create_character(player)

    {:ok, cc} =
      CampaignCharacters.create(game_id, %{
        campaign_id: game_id,
        character_id: character.id,
        owner_id: player.id
      })

    {:ok, _active_cc} = CampaignCharacters.update(cc, %{active: true})
    {:ok, view, _html} = live(conn, "/game/#{game_id}")
    {view, game_id, player}
  end

  describe "auto-roll toggle (issue #145)" do
    test "toggle is visible to a player with an active campaign character", %{conn: conn} do
      {view, _game_id, _player} = mount_player_game(conn)
      assert render(view) =~ "Auto-roll dice"
    end

    test "toggle is not visible to DM", %{conn: conn} do
      {view, _game_id} = mount_dm_game(conn)
      refute render(view) =~ "Auto-roll dice"
    end

    test "toggle is not visible to player without an active campaign character", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      refute render(view) =~ "Auto-roll dice"
    end

    test "toggle_auto_roll flips preference to false and persists", %{conn: conn} do
      {view, game_id, player} = mount_player_game(conn)
      view |> element("[phx-click='toggle_auto_roll']") |> render_click()
      cc = CampaignCharacters.get_active_for_player(game_id, player.id)
      assert cc.auto_roll == false
    end

    test "toggle_auto_roll can toggle back to true", %{conn: conn} do
      {view, game_id, player} = mount_player_game(conn)
      view |> element("[phx-click='toggle_auto_roll']") |> render_click()
      view |> element("[phx-click='toggle_auto_roll']") |> render_click()
      cc = CampaignCharacters.get_active_for_player(game_id, player.id)
      assert cc.auto_roll == true
    end

    test "auto_roll is true after fresh mount (default)", %{conn: conn} do
      {view, _game_id, _player} = mount_player_game(conn)
      html = render(view)
      assert html =~ "translate-x-3.5"
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
      unless Repo.get(EntityPreset, "chest") do
        Repo.insert!(%EntityPreset{
          key: "chest",
          name: "Wooden Chest",
          entity_type: "object",
          object_subtype: "loot_source",
          description: "A sturdy wooden chest."
        })
      end

      chest =
        Repo.insert!(%Entity{
          name: "Treasure Chest",
          type: "object",
          sprite: "chest",
          preset_key: "chest",
          x: 3,
          y: 2,
          hp: 1,
          max_hp: 1,
          tags: [],
          stats: %{"items" => items},
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

  describe "roll prompt overlay (issue #146)" do
    defp broadcast_roll_required(game_id, entity_id) do
      state = SceneServer.get_state(game_id)

      Phoenix.PubSub.broadcast(
        Gibbering.PubSub,
        SceneServer.topic(game_id),
        %Gibbering.Events.EventBatch{
          state_snapshot: %{state | awaiting_roll: true},
          events: [
            %Gibbering.Events.Scene.RollRequired{
              entity_id: entity_id,
              roll_type: :attack,
              dice_expression: "1d20",
              context_label: "Attack vs Goblin"
            }
          ]
        }
      )
    end

    defp broadcast_roll_resolved(game_id) do
      state = SceneServer.get_state(game_id)

      Phoenix.PubSub.broadcast(
        Gibbering.PubSub,
        SceneServer.topic(game_id),
        %Gibbering.Events.EventBatch{
          state_snapshot: %{state | awaiting_roll: false}
        }
      )
    end

    test "roll prompt overlay renders when RollRequired is broadcast", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      broadcast_roll_required(game_id, hero_id)
      html = render(view)
      assert html =~ "Attack vs Goblin"
      assert html =~ "1d20"
      assert html =~ "roll_submit"
    end

    test "roll prompt overlay is absent when awaiting_roll is false", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      broadcast_roll_required(game_id, hero_id)
      broadcast_roll_resolved(game_id)
      refute render(view) =~ "roll_submit"
    end

    test "roll prompt shows roll type label", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      broadcast_roll_required(game_id, hero_id)
      assert render(view) =~ "attack"
    end

    test "roll_submit event calls submit_roll on SceneServer", %{conn: conn} do
      {view, game_id} = mount_combat_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      SceneServer.select_entity(game_id, hero_id)
      # Put server into awaiting_roll state via direct API
      SceneServer.attack_entity(game_id, monster_id, auto_roll: false)
      assert SceneServer.get_state(game_id).awaiting_roll == true

      # Simulate the PubSub message reaching the LiveView
      broadcast_roll_required(game_id, hero_id)
      view |> element("[phx-click='roll_submit']") |> render_click()

      # After submit_roll, awaiting_roll should clear
      assert SceneServer.get_state(game_id).awaiting_roll == false
    end
  end

  describe "tile decorations (issue #125)" do
    defp patch_tile_decoration(game_id, x, y, decoration) do
      map = Repo.get_by!(GameMap, campaign_id: game_id)

      Repo.update_all(
        from(t in GridTile, where: t.map_id == ^map.id and t.x == ^x and t.y == ^y),
        set: [decoration: decoration]
      )
    end

    test "tile with 'bones' decoration renders bones SVG", %{conn: conn} do
      user = register_user()
      conn = log_in_user(conn, user)
      game_id = insert_campaign()
      Campaigns.join_campaign(game_id, user.id)
      patch_tile_decoration(game_id, 1, 3, "bones")
      start_supervised!({SceneServer, game_id})
      {:ok, _view, html} = live(conn, "/game/#{game_id}")
      # bones sprite uses fill="#d8d0b0" for skull and bone elements
      assert html =~ ~s(fill="#d8d0b0")
    end

    test "tile with nil decoration renders no decoration SVG", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      # default fixture tiles have no decorations
      refute render(view) =~ ~s(fill="#d8d0b0")
    end

    test "tile with 'dead_tree' decoration renders tree SVG", %{conn: conn} do
      user = register_user()
      conn = log_in_user(conn, user)
      game_id = insert_campaign()
      Campaigns.join_campaign(game_id, user.id)
      patch_tile_decoration(game_id, 0, 0, "dead_tree")
      start_supervised!({SceneServer, game_id})
      {:ok, _view, html} = live(conn, "/game/#{game_id}")
      # dead_tree sprite uses fill="#4a3018" for the trunk and branches
      assert html =~ ~s(fill="#4a3018")
    end
  end

  describe "movement confirmation UI gate (issue #144)" do
    test "Move button is visible in the action bar for the active entity", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      html = render(view)
      assert html =~ "phx-click=\"activate_move\""
    end

    test "move overlay appears only after Move button is clicked", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # No overlay before selecting the entity
      refute render(view) =~ "phx-click=\"move\""

      # Select entity — still no overlay
      view |> element("#entity-#{hero_id}") |> render_click()
      refute render(view) =~ "phx-click=\"move\""

      # Click Move — overlay appears
      view |> element("[phx-click='activate_move']") |> render_click()
      assert render(view) =~ "phx-click=\"move\""
    end

    test "Escape cancels the move overlay without consuming movement", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view |> element("#entity-#{hero_id}") |> render_click()
      view |> element("[phx-click='activate_move']") |> render_click()
      assert render(view) =~ "phx-click=\"move\""

      # Escape key fires escape_pressed — overlay should clear
      render_keydown(view, "escape_pressed", %{"key" => "Escape"})

      refute render(view) =~ "phx-click=\"move\""

      # Movement was not consumed
      state_after = SceneServer.get_state(game_id)
      mr = get_in(state_after.entities[hero_id], [:action_economy, :movement_remaining])
      assert mr == 30
    end

    test "move overlay uses green fill for normal-cost tiles", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view |> element("#entity-#{hero_id}") |> render_click()
      view |> element("[phx-click='activate_move']") |> render_click()

      html = render(view)
      # Normal terrain tiles render with green overlay fill
      assert html =~ "rgba(74,222,128"
    end

    test "move overlay tiles include a ft cost tooltip", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view |> element("#entity-#{hero_id}") |> render_click()
      view |> element("[phx-click='activate_move']") |> render_click()

      html = render(view)
      assert html =~ " ft</title>"
    end

    test "movement_exhausted badge appears when movement_remaining is 0", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      SceneServer.force_transition_phase(game_id, :in_combat)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Drain 30ft by zigzagging 6 times between (2,1) and (2,2).
      # Hero starts at (2,2) per fixture. Each Chebyshev-1 step costs 5ft.
      view |> element("#entity-#{hero_id}") |> render_click()

      Enum.each(0..5, fn i ->
        view |> element("[phx-click='activate_move']") |> render_click()
        {tx, ty} = if rem(i, 2) == 0, do: {2, 1}, else: {2, 2}

        view
        |> element("[phx-click='move'][phx-value-x='#{tx}'][phx-value-y='#{ty}']")
        |> render_click()
      end)

      html = render(view)
      # Badge uses a red circle — check for the fill color
      assert html =~ ~s(fill="#ef4444")
    end
  end

  describe "event confidentiality" do
    test "player feed does not render :dm_only HP adjustment events", %{conn: conn} do
      dm_user = register_user()
      player_user = register_user()
      game_id = insert_campaign(%{dm_id: dm_user.id})
      Campaigns.join_campaign(game_id, player_user.id)
      start_supervised!({SceneServer, game_id})

      player_conn = log_in_user(conn, player_user)
      {:ok, player_view, _} = live(player_conn, "/game/#{game_id}")

      state = SceneServer.get_state(game_id)
      hero_id = Enum.find_value(state.entities, fn {id, e} -> e.type == "hero" && id end)
      hero_hp = state.entities[hero_id].hp

      # HPAdjusted defaults to visibility: :dm_only
      SceneServer.dm_adjust_hp(game_id, hero_id, -3)

      html = render(player_view)
      refute html =~ "HP: #{hero_hp} →"
      refute html =~ "→ #{hero_hp - 3}"
    end

    test "DM feed shows :dm_only HP adjustment events", %{conn: conn} do
      {dm_view, game_id} = mount_dm_game(conn)

      state = SceneServer.get_state(game_id)
      hero_id = Enum.find_value(state.entities, fn {id, e} -> e.type == "hero" && id end)
      hero_hp = state.entities[hero_id].hp

      SceneServer.dm_adjust_hp(game_id, hero_id, -3)

      assert render(dm_view) =~ "HP: #{hero_hp} → #{hero_hp - 3}"
    end
  end
end
