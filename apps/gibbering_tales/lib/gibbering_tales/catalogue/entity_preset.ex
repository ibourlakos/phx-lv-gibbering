defmodule GibberingTales.Catalogue.EntityPreset do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:key, :string, autogenerate: false}
  @valid_entity_types ~w(hero monster object)
  @valid_subtypes ~w(static_decor loot_source)

  schema "entity_presets" do
    field :name, :string
    field :entity_type, :string
    field :object_subtype, :string
    field :description, :string

    timestamps()
  end

  def changeset(preset, attrs) do
    preset
    |> cast(attrs, [:key, :name, :entity_type, :object_subtype, :description])
    |> validate_required([:key, :name, :entity_type])
    |> validate_inclusion(:entity_type, @valid_entity_types)
    |> validate_inclusion(:object_subtype, @valid_subtypes,
      message: "must be static_decor or loot_source"
    )
  end
end
