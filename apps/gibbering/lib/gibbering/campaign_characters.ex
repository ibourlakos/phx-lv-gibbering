defmodule Gibbering.CampaignCharacters do
  @moduledoc "Context for managing campaign character instances."

  import Ecto.Query

  alias Gibbering.{Repo, CampaignCharacter}

  @doc "Returns all campaign characters for the given campaign."
  def list_for_campaign(campaign_id) do
    CampaignCharacter
    |> where(campaign_id: ^campaign_id)
    |> order_by(:id)
    |> Repo.all()
  end

  @doc "Returns campaign characters with their character template, owner, and controller preloaded."
  def list_for_campaign_preloaded(campaign_id) do
    CampaignCharacter
    |> where(campaign_id: ^campaign_id)
    |> order_by(:id)
    |> preload([:character, :owner, :controller])
    |> Repo.all()
  end

  @doc "Returns `{:ok, campaign_character}` for the given campaign and id, or `{:error, :not_found}`."
  def get(campaign_id, id) do
    case Repo.get_by(CampaignCharacter, id: id, campaign_id: campaign_id) do
      nil -> {:error, :not_found}
      cc -> {:ok, cc}
    end
  end

  @doc "Creates a campaign character scoped to `campaign_id`."
  def create(campaign_id, attrs) do
    attrs = Map.put(attrs, :campaign_id, campaign_id)

    %CampaignCharacter{}
    |> CampaignCharacter.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Applies DM updates (active, controller, overrides) to an existing campaign character."
  def update(%CampaignCharacter{} = cc, attrs) do
    cc
    |> CampaignCharacter.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns the active `CampaignCharacter` owned by `user_id` in `campaign_id`, or `nil`.
  Used to load the player's auto-roll preference in `GameLive`.
  """
  def get_active_for_player(campaign_id, user_id) do
    CampaignCharacter
    |> where(
      [cc],
      cc.campaign_id == ^campaign_id and cc.owner_id == ^user_id and cc.active == true
    )
    |> limit(1)
    |> Repo.one()
  end

  @doc "Sets the auto-roll preference on the given `CampaignCharacter`."
  def set_auto_roll(%CampaignCharacter{} = cc, value) when is_boolean(value) do
    cc
    |> CampaignCharacter.auto_roll_changeset(%{auto_roll: value})
    |> Repo.update()
  end
end
