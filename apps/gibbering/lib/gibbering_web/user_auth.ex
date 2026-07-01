defmodule GibberingWeb.UserAuth do
  @moduledoc """
  Plug and LiveView on_mount hooks for authentication.

  Usage in router:
    pipe_through [:browser, :fetch_current_user]

  Usage in live_session:
    live_session :authenticated,
      on_mount: [{GibberingWeb.UserAuth, :ensure_authenticated}]
  """

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

  alias GibberingTales.Accounts

  # ---------------------------------------------------------------------------
  # Controller plugs
  # ---------------------------------------------------------------------------

  def fetch_current_user(conn, _opts) do
    user =
      case get_session(conn, :user_id) do
        nil -> nil
        id -> Accounts.get_user_by_id(id)
      end

    assign(conn, :current_user, user)
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access this page.")
      |> redirect(to: "/login")
      |> halt()
    end
  end

  def log_in_user(conn, user) do
    conn
    |> renew_session()
    |> put_session(:user_id, user.id)
  end

  def log_out_user(conn) do
    conn
    |> renew_session()
    |> delete_session(:user_id)
  end

  defp renew_session(conn), do: configure_session(conn, renew: true)

  # ---------------------------------------------------------------------------
  # LiveView on_mount hooks
  # ---------------------------------------------------------------------------

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(session, socket)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(session, socket)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must be logged in to access this page.")
        |> Phoenix.LiveView.redirect(to: "/login")

      {:halt, socket}
    end
  end

  def on_mount(:ensure_authenticated_with_return, params, session, socket) do
    socket = mount_current_user(session, socket)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      return_to = build_return_path(socket, params)

      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must be logged in to access this page.")
        |> Phoenix.LiveView.redirect(to: "/login?return_to=#{URI.encode(return_to)}")

      {:halt, socket}
    end
  end

  defp build_return_path(_socket, %{"token" => token}), do: "/invites/#{token}"
  defp build_return_path(_socket, _params), do: "/"

  defp mount_current_user(session, socket) do
    user =
      case Map.get(session, "user_id") do
        nil -> nil
        id -> Accounts.get_user_by_id(id)
      end

    Phoenix.Component.assign(socket, :current_user, user)
  end
end
