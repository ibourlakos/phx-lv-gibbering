defmodule Gibbering.GameMap do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maps" do
    field :x_extent, :integer, default: 10
    field :y_extent, :integer, default: 10
    field :tile_size, :integer, default: 32

    belongs_to :campaign, Gibbering.Campaign
    has_many :tiles, Gibbering.GridTile, foreign_key: :map_id

    timestamps()
  end

  def changeset(map, attrs) do
    map
    |> cast(attrs, [:x_extent, :y_extent, :tile_size, :campaign_id])
    |> validate_required([:x_extent, :y_extent, :tile_size, :campaign_id])
  end
end
