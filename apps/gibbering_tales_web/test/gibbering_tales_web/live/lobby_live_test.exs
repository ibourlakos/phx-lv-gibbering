defmodule GibberingTalesWeb.LobbyLiveTest do
  use GibberingTalesWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import GibberingTalesWeb.EngineFixtures
  import GibberingTales.AccountsFixtures
  import Ecto.Query, only: [from: 2]

  alias GibberingTales.{Repo, Entity, Campaigns}

  # ---------------------------------------------------------------------------
  # Shared setup
  # ---------------------------------------------------------------------------

  defp setup_lobby(_ctx) do
    dm = register_user()
    player = register_user()
    game_id = insert_campaign(%{dm_id: dm.id})
    Campaigns.join_campaign(game_id, dm.id)
    Campaigns.join_campaign(game_id, player.id)
    hero = Repo.one(from e in Entity, where: e.campaign_id == ^game_id and e.type == "hero")
    %{dm: dm, player: player, game_id: game_id, hero: hero}
  end

  # ---------------------------------------------------------------------------
  # Mount / access control
  # ---------------------------------------------------------------------------

  describe "mount" do
    setup :setup_lobby

    test "DM mounts lobby and sees campaign name and hero card", ctx do
      conn = log_in_user(ctx.conn, ctx.dm)
      {:ok, _view, html} = live(conn, "/lobby/#{ctx.game_id}")
      assert html =~ "Test Campaign"
      assert html =~ ctx.hero.name
    end

    test "player member mounts lobby and sees hero card", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, _view, html} = live(conn, "/lobby/#{ctx.game_id}")
      assert html =~ ctx.hero.name
    end

    test "non-member is redirected", ctx do
      outsider = register_user()
      conn = log_in_user(ctx.conn, outsider)

      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, "/lobby/#{ctx.game_id}")
    end

    test "DM sees Add Character Slot button", ctx do
      conn = log_in_user(ctx.conn, ctx.dm)
      {:ok, _view, html} = live(conn, "/lobby/#{ctx.game_id}")
      assert html =~ "Add Character Slot"
    end

    test "player does not see Add Character Slot button", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, _view, html} = live(conn, "/lobby/#{ctx.game_id}")
      refute html =~ "Add Character Slot"
    end
  end

  # ---------------------------------------------------------------------------
  # Claim / release slot
  # ---------------------------------------------------------------------------

  describe "claim_slot" do
    setup :setup_lobby

    test "player claims an unclaimed slot — YOU badge appears", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      view
      |> element("[phx-click='claim_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      html = render(view)
      assert html =~ "YOU"
      assert html =~ "Playing as"
    end

    test "player cannot claim a second slot — UI hides claim button after first claim", ctx do
      Repo.insert!(%Entity{
        name: "Second Hero",
        type: "hero",
        sprite: "human_fighter",
        x: 1,
        y: 1,
        hp: 10,
        max_hp: 10,
        tags: [],
        stats: %{"speed" => 30},
        campaign_id: ctx.game_id
      })

      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      view
      |> element("[phx-click='claim_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      # After claiming, the other card shows the UI gate text instead of a claim button
      assert render(view) =~ "Claim another slot first"
    end

    test "event handler rejects double-claim — second entity stays unclaimed", ctx do
      second_hero =
        Repo.insert!(%Entity{
          name: "Second Hero",
          type: "hero",
          sprite: "human_fighter",
          x: 1,
          y: 1,
          hp: 10,
          max_hp: 10,
          tags: [],
          stats: %{"speed" => 30},
          campaign_id: ctx.game_id
        })

      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      view
      |> element("[phx-click='claim_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      # Bypass UI gate and send the event directly
      render_click(view, "claim_slot", %{"id" => to_string(second_hero.id)})

      updated = Repo.get!(Entity, second_hero.id)
      assert Map.get(updated.stats, "claimed_by") == nil
    end

    test "player releases their slot — claim button reappears", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      view
      |> element("[phx-click='claim_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      view
      |> element("[phx-click='release_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      html = render(view)
      refute html =~ "YOU"
      assert html =~ "Play as"
    end
  end

  # ---------------------------------------------------------------------------
  # Add / remove slot (DM-only)
  # ---------------------------------------------------------------------------

  describe "add_slot" do
    setup :setup_lobby

    test "DM adds a character slot — new hero card appears", ctx do
      conn = log_in_user(ctx.conn, ctx.dm)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      entities_before =
        Repo.all(from e in Entity, where: e.campaign_id == ^ctx.game_id and e.type == "hero")

      view |> element("[phx-click='add_slot']") |> render_click()

      entities_after =
        Repo.all(from e in Entity, where: e.campaign_id == ^ctx.game_id and e.type == "hero")

      assert length(entities_after) == length(entities_before) + 1
      assert render(view) =~ "Adventurer"
    end

    test "non-DM does not see add slot button", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, _view, html} = live(conn, "/lobby/#{ctx.game_id}")
      refute html =~ "Add Character Slot"
    end

    test "event handler rejects non-DM add — no entity inserted", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      count_before =
        Repo.aggregate(
          from(e in Entity, where: e.campaign_id == ^ctx.game_id and e.type == "hero"),
          :count
        )

      # Bypass UI gate and send event directly
      render_click(view, "add_slot", %{})

      count_after =
        Repo.aggregate(
          from(e in Entity, where: e.campaign_id == ^ctx.game_id and e.type == "hero"),
          :count
        )

      assert count_after == count_before
    end
  end

  describe "remove_slot" do
    setup :setup_lobby

    test "DM removes a slot — entity deleted from DB", ctx do
      conn = log_in_user(ctx.conn, ctx.dm)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      view
      |> element("[phx-click='remove_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      assert Repo.get(Entity, ctx.hero.id) == nil
      refute render(view) =~ ctx.hero.name
    end

    test "non-DM cannot remove a slot — entity survives", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      # Bypass UI gate (button only renders for DM)
      render_click(view, "remove_slot", %{"id" => to_string(ctx.hero.id)})

      assert Repo.get(Entity, ctx.hero.id) != nil
    end
  end

  # ---------------------------------------------------------------------------
  # Edit / save slot
  # ---------------------------------------------------------------------------

  describe "edit_slot" do
    setup :setup_lobby

    test "player edits their claimed slot — new name persisted", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      view
      |> element("[phx-click='claim_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      view
      |> element("[phx-click='edit_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      view
      |> form("form[phx-submit='save_slot']", %{"name" => "Zara the Bold"})
      |> render_submit()

      updated = Repo.get!(Entity, ctx.hero.id)
      assert updated.name == "Zara the Bold"
      assert render(view) =~ "Zara the Bold"
    end

    test "cancel_edit dismisses the inline form", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, view, _html} = live(conn, "/lobby/#{ctx.game_id}")

      view
      |> element("[phx-click='claim_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      view
      |> element("[phx-click='edit_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      assert render(view) =~ "phx-submit=\"save_slot\""

      view |> element("[phx-click='cancel_edit']") |> render_click()

      refute render(view) =~ "phx-submit=\"save_slot\""
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub refresh
  # ---------------------------------------------------------------------------

  describe "PubSub refresh" do
    setup :setup_lobby

    test "slot claim on one connection reflects on another mounted view", ctx do
      dm_conn = log_in_user(build_conn(), ctx.dm)
      player_conn = log_in_user(ctx.conn, ctx.player)

      {:ok, dm_view, _} = live(dm_conn, "/lobby/#{ctx.game_id}")
      {:ok, player_view, _} = live(player_conn, "/lobby/#{ctx.game_id}")

      player_view
      |> element("[phx-click='claim_slot'][phx-value-id='#{ctx.hero.id}']")
      |> render_click()

      # DM view receives :refresh broadcast and re-renders
      dm_html = render(dm_view)
      assert dm_html =~ ctx.player.username
    end
  end
end
