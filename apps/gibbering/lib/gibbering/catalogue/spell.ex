defmodule Gibbering.Catalogue.Spell do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:key, :string, autogenerate: false}
  schema "spells" do
    field :name, :string
    field :level, :integer
    field :school, :string
    field :casting_time, :string
    field :range, :string
    field :description, :string
    field :damage_dice, :string
    field :damage_type, :string
    field :attack_type, :string
    field :save, :string
    field :tags, {:array, :string}

    timestamps()
  end

  def changeset(spell, attrs) do
    spell
    |> cast(attrs, [
      :key,
      :name,
      :level,
      :school,
      :casting_time,
      :range,
      :description,
      :damage_dice,
      :damage_type,
      :attack_type,
      :save,
      :tags
    ])
    |> validate_required([:key, :name, :level, :school, :casting_time, :range, :description])
  end
end
