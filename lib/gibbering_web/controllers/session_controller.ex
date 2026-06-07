defmodule GibberingWeb.SessionController do
  use GibberingWeb, :controller

  alias Gibbering.Accounts
  alias GibberingWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error: nil)
  end

  def create(conn, %{"session" => %{"username" => username, "password" => password}} = params) do
    case Accounts.authenticate_user(username, password) do
      {:ok, user} ->
        return_to = safe_return_to(params["return_to"])

        conn
        |> UserAuth.log_in_user(user)
        |> put_flash(:info, "Welcome back, #{user.username}!")
        |> redirect(to: return_to)

      {:error, :suspended} ->
        render(conn, :new, error: "This account has been suspended.")

      {:error, :invalid_credentials} ->
        render(conn, :new, error: "Invalid username or password.")
    end
  end

  defp safe_return_to(nil), do: "/"
  defp safe_return_to(""), do: "/"

  defp safe_return_to(path) do
    uri = URI.parse(path)
    if is_nil(uri.host) and String.starts_with?(path, "/"), do: path, else: "/"
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "Logged out.")
    |> redirect(to: "/login")
  end
end
