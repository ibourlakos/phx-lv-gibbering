defmodule Gibbering.Campaigns do
  import Ecto.Query

  alias Gibbering.{Repo, Campaign, CampaignMember}

  def list_campaigns_for_user(user_id) do
    Campaign
    |> join(:inner, [c], m in CampaignMember, on: m.campaign_id == c.id and m.user_id == ^user_id)
    |> order_by([c], asc: c.id)
    |> Repo.all()
  end

  def member?(campaign_id, user_id) do
    Repo.exists?(
      from m in CampaignMember,
        where: m.campaign_id == ^campaign_id and m.user_id == ^user_id
    )
  end

  def join_campaign(campaign_id, user_id) do
    %CampaignMember{}
    |> CampaignMember.changeset(%{campaign_id: campaign_id, user_id: user_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def set_dm(campaign, user_id) do
    campaign
    |> Campaign.changeset(%{dm_id: user_id})
    |> Repo.update()
  end
end
