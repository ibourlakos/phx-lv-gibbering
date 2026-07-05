defmodule GibberingTales.Catalogue.Class do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:key, :string, autogenerate: false}
  schema "classes" do
    field :name, :string
    field :description, :string
    field :hit_die, :string
    field :base_hp, :integer
    field :primary_stats, {:array, :string}
    field :saving_throws, {:array, :string}
    field :armor_proficiencies, {:array, :string}
    field :weapon_proficiencies, {:array, :string}
    field :spellcasting, :boolean
    field :spells, {:array, :string}
    field :features, {:array, :map}
    field :stats, :map

    timestamps()
  end

  def changeset(class, attrs) do
    class
    |> cast(attrs, [
      :key,
      :name,
      :description,
      :hit_die,
      :base_hp,
      :primary_stats,
      :saving_throws,
      :armor_proficiencies,
      :weapon_proficiencies,
      :spellcasting,
      :spells,
      :features,
      :stats
    ])
    |> validate_required([:key, :name, :description, :hit_die, :base_hp])
  end
end
