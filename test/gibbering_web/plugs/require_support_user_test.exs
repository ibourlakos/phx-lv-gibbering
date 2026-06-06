defmodule GibberingWeb.Plugs.RequireSupportUserTest do
  use GibberingWeb.ConnCase, async: true

  alias Gibbering.Admin
  alias GibberingWeb.Plugs.RequireSupportUser

  defp create_support_user do
    {:ok, user} =
      Admin.create_support_user(%{
        email: "plug_test@admin.local",
        password: "hunter2_admin",
        role: "viewer"
      })

    user
  end

  describe "call/2" do
    test "assigns current_support_user when valid id is in session" do
      user = create_support_user()

      conn =
        build_conn()
        |> init_test_session(%{support_user_id: user.id})
        |> RequireSupportUser.call([])

      assert conn.assigns.current_support_user.id == user.id
      refute conn.halted
    end

    test "halts and redirects to /admin/login when session is missing" do
      conn =
        build_conn()
        |> init_test_session(%{})
        |> RequireSupportUser.call([])

      assert conn.halted
      assert redirected_to(conn) == "/admin/login"
    end

    test "halts when session id refers to a deleted user" do
      conn =
        build_conn()
        |> init_test_session(%{support_user_id: 999_999})
        |> RequireSupportUser.call([])

      assert conn.halted
      assert redirected_to(conn) == "/admin/login"
    end
  end
end
