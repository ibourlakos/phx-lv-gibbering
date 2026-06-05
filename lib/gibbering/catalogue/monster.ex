defmodule Gibbering.Catalogue.Monster do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:key, :string, autogenerate: false}
  schema "monsters" do
    field :name, :string
    field :size, :string
    field :monster_type, :string
    field :alignment, :string
    field :armor_class, :integer
    field :hit_points, :integer
    field :hit_dice, :string
    field :speed, :map
    field :strength, :integer
    field :dexterity, :integer
    field :constitution, :integer
    field :intelligence, :integer
    field :wisdom, :integer
    field :charisma, :integer
    field :challenge_rating, :string
    field :xp_reward, :integer
    field :source_license, :string
    field :stat_block, :map

    timestamps()
  end

  def changeset(monster, attrs) do
    monster
    |> cast(attrs, [
      :key,
      :name,
      :size,
      :monster_type,
      :alignment,
      :armor_class,
      :hit_points,
      :hit_dice,
      :speed,
      :strength,
      :dexterity,
      :constitution,
      :intelligence,
      :wisdom,
      :charisma,
      :challenge_rating,
      :xp_reward,
      :source_license,
      :stat_block
    ])
    |> validate_required([:key, :name])
  end
end
