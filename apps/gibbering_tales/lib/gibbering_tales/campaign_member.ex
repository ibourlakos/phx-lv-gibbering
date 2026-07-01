defmodule GibberingTales.CampaignMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "campaign_members" do
    belongs_to :campaign, GibberingTales.Campaign
    belongs_to :user, GibberingTales.Accounts.User
    timestamps()
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:campaign_id, :user_id])
    |> validate_required([:campaign_id, :user_id])
    |> unique_constraint([:campaign_id, :user_id])
  end
end
