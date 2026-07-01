defmodule Gibbering.CampaignMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "campaign_members" do
    belongs_to :campaign, Gibbering.Campaign
    belongs_to :user, Gibbering.Accounts.User
    timestamps()
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:campaign_id, :user_id])
    |> validate_required([:campaign_id, :user_id])
    |> unique_constraint([:campaign_id, :user_id])
  end
end
