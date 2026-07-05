defmodule GibberingTalesAdmin.AdminCampaignsControllerTest do
  use GibberingTalesAdmin.ConnCase, async: true

  import GibberingTales.AccountsFixtures
  import GibberingTales.GameFixtures

  alias GibberingTalesAdmin.Admin

  defp log_in_support(conn) do
    {:ok, actor} =
      Admin.create_support_user(%{
        email: "ctrl#{System.unique_integer([:positive])}@admin.local",
        password: "hunter2_admin",
        role: "admin"
      })

    conn = init_test_session(conn, %{support_user_id: actor.id})
    {conn, actor}
  end

  describe "GET /admin/campaigns" do
    test "lists campaigns when authenticated", %{conn: conn} do
      {conn, _actor} = log_in_support(conn)
      user = register_user()
      campaign_id = insert_campaign(%{name: "My Campaign", dm_id: user.id})

      html = conn |> get("/campaigns") |> html_response(200)
      assert html =~ "My Campaign"
      _ = campaign_id
    end

    test "redirects unauthenticated", %{conn: conn} do
      conn = get(conn, "/campaigns")
      assert redirected_to(conn) == "/login"
    end
  end

  describe "GET /admin/campaigns/:id" do
    test "shows campaign detail when authenticated", %{conn: conn} do
      {conn, _actor} = log_in_support(conn)
      user = register_user()
      campaign_id = insert_campaign(%{name: "Detail Campaign", dm_id: user.id})

      html = conn |> get("/campaigns/#{campaign_id}") |> html_response(200)
      assert html =~ "Detail Campaign"
    end

    test "redirects unauthenticated", %{conn: conn} do
      user = register_user()
      campaign_id = insert_campaign(%{dm_id: user.id})
      conn = get(conn, "/campaigns/#{campaign_id}")
      assert redirected_to(conn) == "/login"
    end
  end

  describe "POST /admin/campaigns/:id/force_close" do
    test "closes campaign and redirects to show", %{conn: conn} do
      {conn, _actor} = log_in_support(conn)
      user = register_user()
      campaign_id = insert_campaign(%{dm_id: user.id})

      conn =
        post(conn, "/campaigns/#{campaign_id}/force_close", %{
          "reason" => "admin test closure"
        })

      assert redirected_to(conn) == "/campaigns/#{campaign_id}"

      campaign = GibberingTales.Campaigns.get!(campaign_id)
      assert campaign.status == "ended"
    end

    test "redirects unauthenticated", %{conn: conn} do
      user = register_user()
      campaign_id = insert_campaign(%{dm_id: user.id})
      conn = post(conn, "/campaigns/#{campaign_id}/force_close", %{"reason" => "nope"})
      assert redirected_to(conn) == "/login"
    end
  end
end
