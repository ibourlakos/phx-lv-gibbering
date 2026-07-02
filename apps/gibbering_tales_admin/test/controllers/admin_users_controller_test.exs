defmodule GibberingTalesAdmin.AdminUsersControllerTest do
  use GibberingTalesAdmin.ConnCase, async: true

  import GibberingTales.AccountsFixtures

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

  describe "GET /admin/users" do
    test "lists users when authenticated", %{conn: conn} do
      {conn, _actor} = log_in_support(conn)
      user = register_user()
      html = conn |> get("/users") |> html_response(200)
      assert html =~ user.username
    end

    test "redirects unauthenticated", %{conn: conn} do
      conn = get(conn, "/users")
      assert redirected_to(conn) == "/login"
    end

    test "filters by username search", %{conn: conn} do
      {conn, _actor} = log_in_support(conn)
      unique = "findme#{System.unique_integer([:positive])}"
      user = register_user(%{"username" => unique})
      _other = register_user()

      html = conn |> get("/users", %{"search" => unique}) |> html_response(200)
      assert html =~ user.username
      refute html =~ _other.username
    end
  end

  describe "GET /admin/users/:id" do
    test "shows user detail when authenticated", %{conn: conn} do
      {conn, _actor} = log_in_support(conn)
      user = register_user()

      html = conn |> get("/users/#{user.id}") |> html_response(200)
      assert html =~ user.username
    end

    test "redirects unauthenticated", %{conn: conn} do
      user = register_user()
      conn = get(conn, "/users/#{user.id}")
      assert redirected_to(conn) == "/login"
    end
  end

  describe "POST /admin/users/:id/suspend" do
    test "suspends user and redirects to show", %{conn: conn} do
      {conn, _actor} = log_in_support(conn)
      user = register_user()

      conn = post(conn, "/users/#{user.id}/suspend")
      assert redirected_to(conn) == "/users/#{user.id}"

      updated = GibberingTales.Accounts.get_user_by_id(user.id)
      assert updated.suspended_at != nil
    end

    test "redirects unauthenticated", %{conn: conn} do
      user = register_user()
      conn = post(conn, "/users/#{user.id}/suspend")
      assert redirected_to(conn) == "/login"
    end
  end

  describe "POST /admin/users/:id/unsuspend" do
    test "unsuspends user and redirects to show", %{conn: conn} do
      {conn, actor} = log_in_support(conn)
      user = register_user()
      Admin.suspend_user(actor.id, user.id)

      conn = post(conn, "/users/#{user.id}/unsuspend")
      assert redirected_to(conn) == "/users/#{user.id}"

      updated = GibberingTales.Accounts.get_user_by_id(user.id)
      assert is_nil(updated.suspended_at)
    end
  end
end
