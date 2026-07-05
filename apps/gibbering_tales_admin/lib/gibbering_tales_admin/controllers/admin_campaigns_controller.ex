defmodule GibberingTalesAdmin.AdminCampaignsController do
  use GibberingTalesAdmin, :controller

  alias GibberingTalesAdmin.Admin

  def index(conn, _params) do
    campaigns = Admin.list_all_campaigns()
    render(conn, :index, campaigns: campaigns)
  end

  def show(conn, %{"id" => id}) do
    campaign = Admin.get_campaign_with_members(String.to_integer(id))

    render(conn, :show,
      campaign: campaign,
      current_support_user: conn.assigns.current_support_user
    )
  end

  def force_close(conn, %{"id" => id, "reason" => reason}) do
    actor = conn.assigns.current_support_user
    Admin.force_close_campaign(actor.id, String.to_integer(id), reason)
    redirect(conn, to: "/campaigns/#{id}")
  end

  def force_close(conn, %{"id" => id}) do
    force_close(conn, %{"id" => id, "reason" => ""})
  end

  def remove_member(conn, %{"id" => id, "user_id" => user_id, "reason" => reason}) do
    actor = conn.assigns.current_support_user

    case Admin.remove_campaign_member(
           actor.id,
           String.to_integer(id),
           String.to_integer(user_id),
           reason
         ) do
      {:ok, _} ->
        redirect(conn, to: "/campaigns/#{id}")

      {:error, :forbidden} ->
        send_resp(conn, 403, "Forbidden")

      {:error, _reason} ->
        redirect(conn, to: "/campaigns/#{id}")
    end
  end
end
