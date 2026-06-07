defmodule Gibbering.Campaigns do
  @moduledoc "Context for campaign management, membership, and DM assignment."

  import Ecto.Query

  alias Gibbering.{Repo, Campaign, CampaignMember, CampaignCharacter}
  alias Gibbering.Accounts.User

  @doc "Returns the campaign with the given id, or nil."
  def get(id), do: Repo.get(Campaign, id)

  @doc "Returns the campaign with the given id, raising if not found."
  def get!(id), do: Repo.get!(Campaign, id)

  @doc "Returns all users who are members of the given campaign, ordered by username."
  def list_members(campaign_id) do
    User
    |> join(:inner, [u], m in CampaignMember,
      on: m.campaign_id == ^campaign_id and m.user_id == u.id
    )
    |> order_by([u], asc: u.username)
    |> Repo.all()
  end

  @doc "Returns all campaigns the given user is a member of."
  def list_campaigns_for_user(user_id) do
    Campaign
    |> join(:inner, [c], m in CampaignMember, on: m.campaign_id == c.id and m.user_id == ^user_id)
    |> order_by([c], asc: c.id)
    |> Repo.all()
  end

  @doc """
  Returns `[{campaign, [campaign_characters]}]` for the given user.

  Each campaign has `dm` preloaded. Each campaign_character has `character` preloaded.
  Only campaign_characters owned by `user_id` are included.
  """
  def list_campaigns_for_user_with_characters(user_id) do
    campaigns =
      Campaign
      |> join(:inner, [c], m in CampaignMember,
        on: m.campaign_id == c.id and m.user_id == ^user_id
      )
      |> order_by([c], asc: c.id)
      |> preload(:dm)
      |> Repo.all()

    ccs_by_campaign =
      CampaignCharacter
      |> where([cc], cc.owner_id == ^user_id)
      |> where([cc], cc.campaign_id in ^Enum.map(campaigns, & &1.id))
      |> preload(:character)
      |> Repo.all()
      |> Enum.group_by(& &1.campaign_id)

    Enum.map(campaigns, fn campaign ->
      {campaign, Map.get(ccs_by_campaign, campaign.id, [])}
    end)
  end

  @doc "Returns true when the user is a member of the campaign."
  def member?(campaign_id, user_id) do
    Repo.exists?(
      from m in CampaignMember,
        where: m.campaign_id == ^campaign_id and m.user_id == ^user_id
    )
  end

  @doc "Adds a user as a campaign member. No-ops if already a member."
  def join_campaign(campaign_id, user_id) do
    %CampaignMember{}
    |> CampaignMember.changeset(%{campaign_id: campaign_id, user_id: user_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc "Assigns a user as DM of the campaign."
  def set_dm(campaign, user_id) do
    campaign
    |> Campaign.changeset(%{dm_id: user_id})
    |> Repo.update()
  end
end
