defmodule GibberingWeb.Plugs.RequireSupportUser do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Gibbering.Admin

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :support_user_id) do
      nil ->
        conn |> redirect(to: "/admin/login") |> halt()

      id ->
        case Admin.get_support_user_by_id(id) do
          nil ->
            conn |> redirect(to: "/admin/login") |> halt()

          user ->
            assign(conn, :current_support_user, user)
        end
    end
  end
end
