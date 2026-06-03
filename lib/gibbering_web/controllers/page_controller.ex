defmodule GibberingWeb.PageController do
  use GibberingWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
