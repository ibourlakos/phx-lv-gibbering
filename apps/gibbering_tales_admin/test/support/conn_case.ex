defmodule GibberingTalesAdmin.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint GibberingTalesAdmin.Endpoint

      use GibberingTalesAdmin, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import GibberingTalesAdmin.ConnCase
    end
  end

  setup tags do
    GibberingTalesAdmin.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc "Puts a support_user_id in the conn session, simulating an admin login."
  def log_in_support_user(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:support_user_id, user.id)
  end
end
