defmodule Gibbering.Entity do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_types ~w(hero monster object)
  @valid_races ~w(human elf gnome)
  @valid_classes ~w(fighter wizard rogue)

  schema "entities" do
    field :name, :string
    field :type, :string
    field :sprite, :string
    field :race, :string, default: "human"
    field :class, :string, default: "fighter"
    field :x, :integer
    field :y, :integer
    field :hp, :integer
    field :max_hp, :integer
    field :level, :integer, default: 1
    field :temp_hp, :integer, default: 0
    field :challenge_rating, :decimal
    field :xp_reward, :integer
    field :tags, {:array, :string}, default: []
    field :stats, :map, default: %{}
    field :preset_key, :string

    belongs_to :campaign, Gibbering.Campaign

    timestamps()
  end

  def changeset(entity, attrs) do
    entity
    |> cast(attrs, [
      :name,
      :type,
      :sprite,
      :race,
      :class,
      :x,
      :y,
      :hp,
      :max_hp,
      :level,
      :temp_hp,
      :challenge_rating,
      :xp_reward,
      :tags,
      :stats,
      :preset_key,
      :campaign_id
    ])
    |> validate_required([:name, :type, :sprite, :x, :y, :hp, :max_hp, :campaign_id])
    |> validate_inclusion(:type, @valid_types)
    |> validate_inclusion(:race, @valid_races)
    |> validate_inclusion(:class, @valid_classes)
    |> validate_number(:level, greater_than_or_equal_to: 1, less_than_or_equal_to: 20)
    |> validate_number(:temp_hp, greater_than_or_equal_to: 0)
    |> validate_number(:xp_reward, greater_than_or_equal_to: 0)
  end
end
