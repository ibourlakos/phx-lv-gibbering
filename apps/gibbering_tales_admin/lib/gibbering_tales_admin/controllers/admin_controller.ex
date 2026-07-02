defmodule GibberingTalesAdmin.AdminController do
  use GibberingTalesAdmin, :controller

  def index(conn, _params) do
    render(conn, :index, support_user: conn.assigns.current_support_user)
  end
end
