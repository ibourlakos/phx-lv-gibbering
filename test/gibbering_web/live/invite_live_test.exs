defmodule GibberingWeb.InviteLiveTest do
  use GibberingWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Gibbering.AccountsFixtures

  alias Gibbering.{Repo, Campaign, Campaigns, CampaignInviteLinks}
  alias Gibbering.GameFixtures

  setup do
    dm = register_user()
    player = register_user()
    campaign_id = GameFixtures.insert_campaign()
    {:ok, _} = Campaigns.join_campaign(campaign_id, dm.id)
    campaign = Repo.get!(Campaign, campaign_id)
    # Set dm_id so is_dm check works in InviteLive
    campaign = Repo.update!(Campaign.changeset(campaign, %{dm_id: dm.id}))
    {:ok, link} = CampaignInviteLinks.create_for_campaign(campaign_id, dm.id)
    %{dm: dm, player: player, campaign: campaign, link: link}
  end

  describe "unauthenticated visit" do
    test "redirects to login with return_to param", ctx do
      assert {:error, {:redirect, %{to: path}}} = live(ctx.conn, "/invites/#{ctx.link.token}")
      assert path =~ "/login"
      assert path =~ "return_to"
    end
  end

  describe "authenticated visit — valid token" do
    test "shows campaign name and join button", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, _view, html} = live(conn, "/invites/#{ctx.link.token}")
      assert html =~ ctx.campaign.name
      assert html =~ ~r/join/i
    end

    test "joining creates membership and redirects to dashboard", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, view, _html} = live(conn, "/invites/#{ctx.link.token}")

      view |> element("button[phx-click='join']") |> render_click()

      assert Campaigns.member?(ctx.campaign.id, ctx.player.id)
    end

    test "DM visiting their own link sees the campaign without a join button", ctx do
      conn = log_in_user(ctx.conn, ctx.dm)
      {:ok, _view, html} = live(conn, "/invites/#{ctx.link.token}")
      assert html =~ ctx.campaign.name
      refute html =~ ~r/<button[^>]*phx-click="join"/
    end
  end

  describe "authenticated visit — invalid token" do
    test "shows error for expired token", ctx do
      past = DateTime.utc_now() |> DateTime.add(-1, :second) |> DateTime.truncate(:second)
      Repo.update!(Ecto.Changeset.change(ctx.link, expires_at: past))

      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, _view, html} = live(conn, "/invites/#{ctx.link.token}")
      assert html =~ ~r/expired/i
    end

    test "shows error for revoked token", ctx do
      CampaignInviteLinks.revoke(ctx.link)
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, _view, html} = live(conn, "/invites/#{ctx.link.token}")
      assert html =~ ~r/revoked/i
    end

    test "shows error for unknown token", ctx do
      conn = log_in_user(ctx.conn, ctx.player)
      {:ok, _view, html} = live(conn, "/invites/bad_token_here")
      assert html =~ ~r/not found|invalid/i
    end
  end
end
