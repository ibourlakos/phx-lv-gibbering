defmodule GibberingTalesWeb.DashboardLiveTest do
  use GibberingTalesWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import GibberingTales.AccountsFixtures

  alias GibberingTales.Repo
  alias GibberingTales.{Campaign, Campaigns, CampaignCharacters}
  alias GibberingTales.CharactersFixtures

  defp insert_campaign(dm) do
    {:ok, campaign} =
      Repo.insert(%Campaign{
        name: "Campaign #{System.unique_integer([:positive])}",
        dm_id: dm.id
      })

    campaign
  end

  describe "unauthenticated access" do
    test "redirects to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: path}}} = live(conn, "/dashboard")
      assert path =~ "/login"
    end
  end

  describe "player with a campaign and character" do
    setup do
      dm = register_user()
      player = register_user()
      campaign = insert_campaign(dm)
      {:ok, _} = Campaigns.join_campaign(campaign.id, dm.id)
      {:ok, _} = Campaigns.join_campaign(campaign.id, player.id)
      character = CharactersFixtures.create_character(player)

      {:ok, _cc} =
        CampaignCharacters.create(campaign.id, %{
          character_id: character.id,
          owner_id: player.id
        })

      %{dm: dm, player: player, campaign: campaign, character: character}
    end

    test "player sees campaign name and character name", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, _view, html} = live(conn, "/dashboard")
      assert html =~ ctx.campaign.name
      assert html =~ ctx.character.name
    end

    test "DM sees their campaign with a manage link and not the player character", ctx do
      conn = log_in_user(ctx.conn, ctx.dm)
      {:ok, _view, html} = live(conn, "/dashboard")
      assert html =~ ctx.campaign.name
      assert html =~ ~r/manage/i
      refute html =~ ctx.character.name
    end
  end

  describe "player with no campaigns" do
    test "shows empty state with join prompt", %{conn: conn} do
      user = register_user()
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, "/dashboard")
      assert html =~ ~r/no campaigns|join|invite/i
    end
  end

  describe "campaign status badge" do
    test "shows status label on campaign card", ctx do
      dm = register_user()
      campaign = insert_campaign(dm)
      {:ok, _} = Campaigns.join_campaign(campaign.id, dm.id)

      conn = log_in_user(ctx.conn, dm)
      {:ok, _view, html} = live(conn, "/dashboard")
      assert html =~ ~r/lobby/i
    end
  end
end
