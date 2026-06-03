defmodule Gibbering.Entity do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_types ~w(hero monster object)

  schema "entities" do
    field :name, :string
    field :type, :string
    field :sprite, :string
    field :x, :integer
    field :y, :integer
    field :hp, :integer
    field :max_hp, :integer
    field :tags, {:array, :string}, default: []
    field :stats, :map, default: %{}

    belongs_to :campaign, Gibbering.Campaign

    timestamps()
  end

  def changeset(entity, attrs) do
    entity
    |> cast(attrs, [:name, :type, :sprite, :x, :y, :hp, :max_hp, :tags, :stats, :campaign_id])
    |> validate_required([:name, :type, :sprite, :x, :y, :hp, :max_hp, :campaign_id])
    |> validate_inclusion(:type, @valid_types)
  end
end
