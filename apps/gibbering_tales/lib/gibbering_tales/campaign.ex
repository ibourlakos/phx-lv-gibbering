defmodule GibberingTales.Campaign do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_statuses ~w(lobby active ended)

  schema "campaigns" do
    field :name, :string
    field :status, :string, default: "lobby"

    belongs_to :dm, GibberingTales.Accounts.User
    belongs_to :active_map, GibberingTales.GameMap
    has_many :maps, GibberingTales.GameMap
    has_many :entities, GibberingTales.Entity
    has_many :campaign_members, GibberingTales.CampaignMember

    timestamps()
  end

  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :status, :dm_id, :active_map_id])
    |> validate_required([:name])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
