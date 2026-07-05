defmodule GibberingTalesWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint GibberingTalesWeb.Endpoint

      use GibberingTalesWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import GibberingTalesWeb.ConnCase
    end
  end

  setup tags do
    GibberingTalesWeb.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc "Puts a user_id in the conn session, simulating a logged-in user."
  def log_in_user(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_id, user.id)
  end
end
