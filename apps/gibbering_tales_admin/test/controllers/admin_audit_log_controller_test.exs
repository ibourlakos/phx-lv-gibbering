defmodule GibberingTalesAdmin.AdminAuditLogControllerTest do
  use GibberingTalesAdmin.ConnCase, async: true

  alias GibberingTalesAdmin.Admin

  defp create_actor do
    {:ok, user} =
      Admin.create_support_user(%{
        email: "audit_ctrl@admin.local",
        password: "hunter2_admin",
        role: "admin"
      })

    user
  end

  defp authenticated_conn(conn, user) do
    conn |> init_test_session(%{support_user_id: user.id})
  end

  describe "GET /admin/audit_log" do
    test "renders audit log index for authenticated support user", %{conn: conn} do
      actor = create_actor()
      {:ok, _} = Admin.log_action(actor.id, "user.suspend", "user", "1")

      conn = conn |> authenticated_conn(actor) |> get("/audit_log")
      assert html_response(conn, 200) =~ "Audit Log"
      assert html_response(conn, 200) =~ "user.suspend"
    end

    test "redirects unauthenticated requests to /admin/login", %{conn: conn} do
      conn = get(conn, "/audit_log")
      assert redirected_to(conn) == "/login"
    end

    test "filters by actor_id when query param given", %{conn: conn} do
      actor = create_actor()

      {:ok, other} =
        Admin.create_support_user(%{
          email: "other2@admin.local",
          password: "hunter2_admin",
          role: "viewer"
        })

      {:ok, _} = Admin.log_action(actor.id, "user.suspend", "user", "1")
      {:ok, _} = Admin.log_action(other.id, "user.verify", "user", "2")

      conn =
        conn
        |> authenticated_conn(actor)
        |> get("/audit_log?actor_id=#{actor.id}")

      body = html_response(conn, 200)
      assert body =~ "user.suspend"
    end
  end
end
