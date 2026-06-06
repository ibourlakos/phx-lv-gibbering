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
end
