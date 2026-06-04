defmodule GibberingWeb.PageController do
  use GibberingWeb, :controller

  alias Gibbering.{Repo, Campaign, Campaigns}
  import Ecto.Query, only: [order_by: 2]

  def home(conn, _params) do
    all_campaigns = Repo.all(order_by(Campaign, asc: :id))

    member_ids =
      case conn.assigns[:current_user] do
        nil ->
          MapSet.new()

        user ->
          user.id
          |> Campaigns.list_campaigns_for_user()
          |> Enum.map(& &1.id)
          |> MapSet.new()
      end

    render(conn, :home, campaigns: all_campaigns, member_ids: member_ids)
  end

  def join(conn, %{"campaign_id" => campaign_id}) do
    user = conn.assigns.current_user

    if user do
      Campaigns.join_campaign(String.to_integer(campaign_id), user.id)

      conn
      |> put_flash(:info, "You joined the campaign.")
      |> redirect(to: "/")
    else
      conn
      |> put_flash(:error, "You must be logged in to join a campaign.")
      |> redirect(to: "/login")
    end
  end
end
