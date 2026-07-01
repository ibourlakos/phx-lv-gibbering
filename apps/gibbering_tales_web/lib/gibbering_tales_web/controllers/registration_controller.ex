defmodule GibberingTalesWeb.RegistrationController do
  use GibberingTalesWeb, :controller

  alias GibberingTales.Accounts
  alias GibberingTalesWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error: nil)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> UserAuth.log_in_user(user)
        |> put_flash(:info, "Welcome, #{user.username}!")
        |> redirect(to: "/")

      {:error, changeset} ->
        errors = format_errors(changeset)
        render(conn, :new, error: errors)
    end
  end

  defp format_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)
    |> Enum.join(", ")
  end
end
