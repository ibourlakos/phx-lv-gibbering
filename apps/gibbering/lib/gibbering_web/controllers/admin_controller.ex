defmodule GibberingWeb.AdminController do
  use GibberingWeb, :controller

  def index(conn, _params) do
    render(conn, :index, support_user: conn.assigns.current_support_user)
  end
end
