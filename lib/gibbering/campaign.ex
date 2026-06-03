defmodule Gibbering.Campaign do
  use Ecto.Schema
  import Ecto.Changeset

  schema "campaigns" do
    field :name, :string
    field :map_width, :integer, default: 10
    field :map_height, :integer, default: 10
    field :tile_size, :integer, default: 32

    has_many :tiles, Gibbering.GridTile
    has_many :entities, Gibbering.Entity

    timestamps()
  end

  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :map_width, :map_height, :tile_size])
    |> validate_required([:name, :map_width, :map_height, :tile_size])
  end
end
