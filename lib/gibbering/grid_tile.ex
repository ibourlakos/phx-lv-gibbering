defmodule Gibbering.GridTile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grid_tiles" do
    field :x, :integer
    field :y, :integer
    field :texture, :string, default: "grass"
    field :walkable, :boolean, default: true
    field :decoration, :string

    belongs_to :campaign, Gibbering.Campaign
  end

  def changeset(tile, attrs) do
    tile
    |> cast(attrs, [:x, :y, :texture, :walkable, :decoration, :campaign_id])
    |> validate_required([:x, :y, :texture, :walkable, :campaign_id])
  end
end
