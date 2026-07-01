defmodule Gibbering.CampaignInvitation do
  @moduledoc "Pending join request or DM invite for a player to enter a campaign."

  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending approved rejected accepted declined)

  schema "campaign_invitations" do
    belongs_to :campaign, Gibbering.Campaign
    belongs_to :user, Gibbering.Accounts.User
    belongs_to :character, Gibbering.Character
    belongs_to :initiated_by, Gibbering.Accounts.User

    field :direction, :string
    field :status, :string, default: "pending"

    timestamps()
  end

  @doc "Changeset for a player-initiated join request."
  def player_request_changeset(inv, attrs) do
    inv
    |> cast(attrs, [:campaign_id, :user_id, :character_id])
    |> validate_required([:campaign_id, :user_id, :character_id])
    |> put_change(:direction, "player_request")
    |> put_change(:status, "pending")
    |> foreign_key_constraint(:campaign_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:character_id)
  end

  @doc "Changeset for a DM-initiated invite."
  def dm_invite_changeset(inv, attrs) do
    inv
    |> cast(attrs, [:campaign_id, :user_id, :initiated_by_id])
    |> validate_required([:campaign_id, :user_id, :initiated_by_id])
    |> put_change(:direction, "dm_invite")
    |> put_change(:status, "pending")
    |> foreign_key_constraint(:campaign_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:initiated_by_id)
  end

  @doc "Changeset for updating invitation status."
  def status_changeset(inv, status) when status in @statuses do
    change(inv, status: status)
  end

  @doc "Changeset for recording the character chosen when accepting a dm_invite."
  def accept_changeset(inv, character_id) do
    inv
    |> change(status: "accepted", character_id: character_id)
    |> foreign_key_constraint(:character_id)
  end
end
