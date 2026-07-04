defmodule GibberingTalesWeb.PageControllerTest do
  @moduledoc false
  use GibberingTalesWeb.ConnCase

  import GibberingTales.AccountsFixtures
  import GibberingTales.GameFixtures

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "The Gibbering Engine"
  end

  describe "POST /campaigns/:campaign_id/join" do
    test "non-numeric campaign id redirects with an error instead of 500", %{conn: conn} do
      user = register_user()
      conn = conn |> log_in_user(user) |> post(~p"/campaigns/abc/join")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "nonexistent campaign id redirects with an error instead of a false success", %{
      conn: conn
    } do
      user = register_user()
      conn = conn |> log_in_user(user) |> post(~p"/campaigns/999999/join")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "valid campaign id joins successfully", %{conn: conn} do
      user = register_user()
      campaign_id = insert_campaign()
      conn = conn |> log_in_user(user) |> post(~p"/campaigns/#{campaign_id}/join")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info)
    end
  end
end
