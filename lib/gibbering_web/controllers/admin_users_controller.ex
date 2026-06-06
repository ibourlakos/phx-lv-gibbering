defmodule GibberingWeb.AdminUsersController do
  use GibberingWeb, :controller

  alias Gibbering.Admin

  def index(conn, params) do
    search = Map.get(params, "search")
    users = Admin.list_users(search: search)
    render(conn, :index, users: users, search: search || "")
  end

  def show(conn, %{"id" => id}) do
    user = Admin.get_user_with_memberships(String.to_integer(id))
    render(conn, :show, user: user)
  end

  def suspend(conn, %{"id" => id}) do
    actor = conn.assigns.current_support_user
    Admin.suspend_user(actor.id, String.to_integer(id))
    redirect(conn, to: "/admin/users/#{id}")
  end

  def unsuspend(conn, %{"id" => id}) do
    actor = conn.assigns.current_support_user
    Admin.unsuspend_user(actor.id, String.to_integer(id))
    redirect(conn, to: "/admin/users/#{id}")
  end
end
