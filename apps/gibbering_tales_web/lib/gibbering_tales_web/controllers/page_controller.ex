defmodule GibberingTalesWeb.PageController do
  use GibberingTalesWeb, :controller

  alias GibberingTales.Repo
  alias GibberingTales.{Campaign, Campaigns}
  import Ecto.Query, only: [order_by: 2]

  def home(conn, _params) do
    all_campaigns =
      Campaign
      |> order_by(asc: :id)
      |> Repo.all()
      |> Repo.preload(:active_map)

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

    cond do
      is_nil(user) ->
        conn
        |> put_flash(:error, "You must be logged in to join a campaign.")
        |> redirect(to: "/login")

      match?({_, ""}, Integer.parse(campaign_id)) ->
        {id, ""} = Integer.parse(campaign_id)

        case Campaigns.join_campaign(id, user.id) do
          {:ok, _member} ->
            conn
            |> put_flash(:info, "You joined the campaign.")
            |> redirect(to: "/")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Could not join that campaign.")
            |> redirect(to: "/")
        end

      true ->
        conn
        |> put_flash(:error, "Could not join that campaign.")
        |> redirect(to: "/")
    end
  end
end
