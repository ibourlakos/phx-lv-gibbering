defmodule GibberingWeb.AdminSessionController do
  use GibberingWeb, :controller

  alias Gibbering.Admin

  def new(conn, _params) do
    if get_session(conn, :support_user_id) do
      redirect(conn, to: "/admin")
    else
      render(conn, :new, error: nil)
    end
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    case Admin.authenticate_support_user(email, password) do
      {:ok, user} ->
        conn
        |> renew_session()
        |> put_session(:support_user_id, user.id)
        |> put_flash(:info, "Welcome, #{user.email}.")
        |> redirect(to: "/admin")

      {:error, :invalid_credentials} ->
        render(conn, :new, error: "Invalid email or password.")
    end
  end

  def delete(conn, _params) do
    conn
    |> renew_session()
    |> delete_session(:support_user_id)
    |> redirect(to: "/admin/login")
  end

  defp renew_session(conn), do: configure_session(conn, renew: true)
end
