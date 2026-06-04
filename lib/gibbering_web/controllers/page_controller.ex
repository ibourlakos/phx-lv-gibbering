defmodule GibberingWeb.PageController do
  use GibberingWeb, :controller

  alias Gibbering.{Repo, Campaign}
  import Ecto.Query, only: [order_by: 2]

  def home(conn, _params) do
    campaigns = Repo.all(order_by(Campaign, asc: :id))
    render(conn, :home, campaigns: campaigns)
  end
end
