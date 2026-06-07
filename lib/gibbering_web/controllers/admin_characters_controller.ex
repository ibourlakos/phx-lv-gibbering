defmodule GibberingWeb.AdminCharactersController do
  use GibberingWeb, :controller

  alias Gibbering.Admin

  plug :require_moderator_role

  def index(conn, params) do
    search = Map.get(params, "search")
    characters = Admin.list_characters_for_admin(search: search)
    render(conn, :index, characters: characters, search: search || "")
  end

  def show(conn, %{"id" => id}) do
    character = Admin.get_character_for_admin!(String.to_integer(id))
    render(conn, :show, character: character)
  end

  defp require_moderator_role(conn, _opts) do
    user = conn.assigns.current_support_user

    if user.role in ~w(moderator admin) do
      conn
    else
      conn
      |> put_flash(:error, "Access restricted to moderators and admins.")
      |> redirect(to: "/admin")
      |> halt()
    end
  end
end
