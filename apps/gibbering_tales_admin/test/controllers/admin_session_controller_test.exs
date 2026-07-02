defmodule GibberingTalesAdmin.AdminSessionControllerTest do
  use GibberingTalesAdmin.ConnCase, async: true

  alias GibberingTalesAdmin.Admin

  defp create_support_user do
    {:ok, user} =
      Admin.create_support_user(%{
        email: "ctrl_test@admin.local",
        password: "hunter2_admin",
        role: "admin"
      })

    user
  end

  describe "GET /admin/login" do
    test "renders the login form", %{conn: conn} do
      conn = get(conn, "/login")
      assert html_response(conn, 200) =~ "Admin Login"
    end

    test "redirects to /admin if already authenticated", %{conn: conn} do
      user = create_support_user()
      conn = conn |> init_test_session(%{support_user_id: user.id}) |> get("/login")
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /admin/login" do
    test "sets session and redirects to /admin on valid credentials", %{conn: conn} do
      create_support_user()

      conn =
        post(conn, "/login", %{
          "session" => %{"email" => "ctrl_test@admin.local", "password" => "hunter2_admin"}
        })

      assert get_session(conn, :support_user_id)
      assert redirected_to(conn) == "/"
    end

    test "re-renders with error on invalid credentials", %{conn: conn} do
      conn =
        post(conn, "/login", %{
          "session" => %{"email" => "nobody@admin.local", "password" => "wrong"}
        })

      assert html_response(conn, 200) =~ "Invalid"
    end
  end

  describe "DELETE /admin/logout" do
    test "clears session and redirects to /admin/login", %{conn: conn} do
      user = create_support_user()

      conn =
        conn
        |> init_test_session(%{support_user_id: user.id})
        |> delete("/logout")

      assert is_nil(get_session(conn, :support_user_id))
      assert redirected_to(conn) == "/login"
    end
  end

  describe "GET /admin (index)" do
    test "renders index for authenticated support user", %{conn: conn} do
      user = create_support_user()
      conn = conn |> init_test_session(%{support_user_id: user.id}) |> get("/")
      assert html_response(conn, 200) =~ "Admin"
    end

    test "redirects unauthenticated requests to /admin/login", %{conn: conn} do
      conn = get(conn, "/")
      assert redirected_to(conn) == "/login"
    end

    test "player session does not grant access to /admin", %{conn: conn} do
      conn = conn |> init_test_session(%{user_id: 1}) |> get("/")
      assert redirected_to(conn) == "/login"
    end
  end
end
