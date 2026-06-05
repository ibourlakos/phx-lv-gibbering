defmodule Gibbering.Catalogue.Race do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:key, :string, autogenerate: false}
  @derive {Jason.Encoder,
           only: [:key, :name, :description, :speed, :stat_bonuses, :traits, :darkvision]}
  schema "races" do
    field :name, :string
    field :description, :string
    field :speed, :integer
    field :stat_bonuses, :map
    field :traits, {:array, :map}
    field :darkvision, :boolean

    timestamps()
  end

  def changeset(race, attrs) do
    race
    |> cast(attrs, [:key, :name, :description, :speed, :stat_bonuses, :traits, :darkvision])
    |> validate_required([:key, :name, :description, :speed])
  end
end
