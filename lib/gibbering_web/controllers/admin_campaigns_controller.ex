defmodule GibberingWeb.AdminCampaignsController do
  use GibberingWeb, :controller

  alias Gibbering.Admin

  def index(conn, _params) do
    campaigns = Admin.list_all_campaigns()
    render(conn, :index, campaigns: campaigns)
  end

  def show(conn, %{"id" => id}) do
    campaign = Admin.get_campaign_with_members(String.to_integer(id))
    render(conn, :show, campaign: campaign)
  end

  def force_close(conn, %{"id" => id, "reason" => reason}) do
    actor = conn.assigns.current_support_user
    Admin.force_close_campaign(actor.id, String.to_integer(id), reason)
    redirect(conn, to: "/admin/campaigns/#{id}")
  end

  def force_close(conn, %{"id" => id}) do
    force_close(conn, %{"id" => id, "reason" => ""})
  end
end
