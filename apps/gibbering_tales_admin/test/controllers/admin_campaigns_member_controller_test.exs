defmodule GibberingTalesAdmin.AdminCampaignsMemberControllerTest do
  use GibberingTalesAdmin.ConnCase, async: true

  import GibberingTales.AccountsFixtures
  import GibberingTales.GameFixtures

  alias GibberingTalesAdmin.Admin
  alias GibberingTales.Campaigns

  defp log_in_support(conn, role \\ "admin") do
    {:ok, actor} =
      Admin.create_support_user(%{
        email: "ctrl#{System.unique_integer([:positive])}@admin.local",
        password: "hunter2_admin",
        role: role
      })

    conn = init_test_session(conn, %{support_user_id: actor.id})
    {conn, actor}
  end

  describe "POST /admin/campaigns/:id/remove_member" do
    test "removes member and redirects to campaign", %{conn: conn} do
      {conn, _actor} = log_in_support(conn)
      dm = register_user()
      player = register_user()
      campaign_id = insert_campaign(%{dm_id: dm.id})
      Campaigns.join_campaign(campaign_id, player.id)

      conn =
        post(conn, "/campaigns/#{campaign_id}/remove_member", %{
          "user_id" => to_string(player.id),
          "reason" => "disruptive"
        })

      assert redirected_to(conn) == "/campaigns/#{campaign_id}"
      refute Campaigns.member?(campaign_id, player.id)
    end

    test "redirects unauthenticated", %{conn: conn} do
      dm = register_user()
      player = register_user()
      campaign_id = insert_campaign(%{dm_id: dm.id})
      Campaigns.join_campaign(campaign_id, player.id)

      conn =
        post(conn, "/campaigns/#{campaign_id}/remove_member", %{
          "user_id" => to_string(player.id),
          "reason" => "nope"
        })

      assert redirected_to(conn) == "/login"
    end

    test "returns 403 for viewer role", %{conn: conn} do
      {conn, _actor} = log_in_support(conn, "viewer")
      dm = register_user()
      player = register_user()
      campaign_id = insert_campaign(%{dm_id: dm.id})
      Campaigns.join_campaign(campaign_id, player.id)

      conn =
        post(conn, "/campaigns/#{campaign_id}/remove_member", %{
          "user_id" => to_string(player.id),
          "reason" => "nope"
        })

      assert conn.status == 403
    end
  end
end
