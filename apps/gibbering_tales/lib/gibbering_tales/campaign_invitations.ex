defmodule GibberingTales.CampaignInvitations do
  @moduledoc "Context for the bidirectional campaign joining flows."

  import Ecto.Query

  alias Ecto.Multi
  alias GibberingTales.{Repo, CampaignInvitation, CampaignCharacters, Campaigns}

  @doc "Player submits a request to join a campaign with a chosen character."
  def request_to_join(campaign_id, user_id, character_id) do
    %CampaignInvitation{}
    |> CampaignInvitation.player_request_changeset(%{
      campaign_id: campaign_id,
      user_id: user_id,
      character_id: character_id
    })
    |> Repo.insert()
  end

  @doc "DM invites a player to a campaign."
  def invite_player(campaign_id, user_id, invited_by_id) do
    %CampaignInvitation{}
    |> CampaignInvitation.dm_invite_changeset(%{
      campaign_id: campaign_id,
      user_id: user_id,
      initiated_by_id: invited_by_id
    })
    |> Repo.insert()
  end

  @doc "Returns pending invitations for a campaign (both player requests and DM invites)."
  def list_pending_for_campaign(campaign_id) do
    CampaignInvitation
    |> where(campaign_id: ^campaign_id, status: "pending")
    |> Repo.all()
  end

  @doc "Returns pending invitations for a user across all campaigns."
  def list_pending_for_user(user_id) do
    CampaignInvitation
    |> where(user_id: ^user_id, status: "pending")
    |> Repo.all()
  end

  @doc "DM approves a player_request: creates CampaignCharacter, joins campaign, marks approved."
  def approve(%CampaignInvitation{direction: "player_request"} = inv) do
    Multi.new()
    |> Multi.run(:campaign_character, fn _repo, _changes ->
      CampaignCharacters.create(inv.campaign_id, %{
        campaign_id: inv.campaign_id,
        character_id: inv.character_id,
        owner_id: inv.user_id,
        controller_id: inv.user_id
      })
    end)
    |> Multi.run(:membership, fn _repo, _changes ->
      Campaigns.join_campaign(inv.campaign_id, inv.user_id)
    end)
    |> Multi.update(:invitation, CampaignInvitation.status_changeset(inv, "approved"))
    |> Repo.transaction()
    |> case do
      {:ok, %{invitation: updated}} -> {:ok, updated}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  @doc "DM rejects a player_request."
  def reject(%CampaignInvitation{} = inv) do
    inv
    |> CampaignInvitation.status_changeset("rejected")
    |> Repo.update()
  end

  @doc "Player accepts a dm_invite, providing their chosen character."
  def accept(%CampaignInvitation{direction: "dm_invite"} = inv, character_id) do
    Multi.new()
    |> Multi.run(:campaign_character, fn _repo, _changes ->
      CampaignCharacters.create(inv.campaign_id, %{
        campaign_id: inv.campaign_id,
        character_id: character_id,
        owner_id: inv.user_id,
        controller_id: inv.user_id
      })
    end)
    |> Multi.run(:membership, fn _repo, _changes ->
      Campaigns.join_campaign(inv.campaign_id, inv.user_id)
    end)
    |> Multi.update(:invitation, CampaignInvitation.accept_changeset(inv, character_id))
    |> Repo.transaction()
    |> case do
      {:ok, %{invitation: updated}} -> {:ok, updated}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  @doc "Player declines a dm_invite."
  def decline(%CampaignInvitation{} = inv) do
    inv
    |> CampaignInvitation.status_changeset("declined")
    |> Repo.update()
  end
end
