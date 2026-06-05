defmodule GibberingWeb.SessionController do
  use GibberingWeb, :controller

  alias Gibbering.Accounts
  alias GibberingWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error: nil)
  end

  def create(conn, %{"session" => %{"username" => username, "password" => password}}) do
    case Accounts.authenticate_user(username, password) do
      {:ok, user} ->
        conn
        |> UserAuth.log_in_user(user)
        |> put_flash(:info, "Welcome back, #{user.username}!")
        |> redirect(to: "/")

      {:error, :invalid_credentials} ->
        render(conn, :new, error: "Invalid username or password.")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "Logged out.")
    |> redirect(to: "/login")
  end
end
