defmodule Gibbering.Character do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_races ~w(human elf gnome)
  @valid_classes ~w(fighter wizard rogue)
  @valid_alignments ~w(
    lawful_good neutral_good chaotic_good
    lawful_neutral true_neutral chaotic_neutral
    lawful_evil neutral_evil chaotic_evil
  )

  schema "characters" do
    belongs_to :user, Gibbering.Accounts.User

    field :name, :string
    field :race, :string
    field :class, :string
    field :level, :integer, default: 1
    field :alignment, :string, default: "true_neutral"
    field :background, :string

    field :strength, :integer, default: 10
    field :dexterity, :integer, default: 10
    field :constitution, :integer, default: 10
    field :intelligence, :integer, default: 10
    field :wisdom, :integer, default: 10
    field :charisma, :integer, default: 10

    field :skill_proficiencies, {:array, :string}, default: []
    field :saving_throw_proficiencies, {:array, :string}, default: []
    field :tool_proficiencies, {:array, :string}, default: []
    field :languages, {:array, :string}, default: []
    field :spells_known, {:array, :string}, default: []

    field :personality_traits, :string
    field :ideals, :string
    field :bonds, :string
    field :flaws, :string

    field :appearance, :map, default: %{}
    field :life_events, {:array, :map}, default: []
    field :starting_items, {:array, :map}, default: []

    timestamps()
  end

  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :name,
      :race,
      :class,
      :level,
      :alignment,
      :background,
      :strength,
      :dexterity,
      :constitution,
      :intelligence,
      :wisdom,
      :charisma,
      :skill_proficiencies,
      :saving_throw_proficiencies,
      :tool_proficiencies,
      :languages,
      :spells_known,
      :personality_traits,
      :ideals,
      :bonds,
      :flaws,
      :appearance,
      :life_events,
      :starting_items
    ])
    |> validate_required([:name, :race, :class])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_inclusion(:race, @valid_races)
    |> validate_inclusion(:class, @valid_classes)
    |> validate_inclusion(:alignment, @valid_alignments)
    |> validate_number(:level, greater_than_or_equal_to: 1, less_than_or_equal_to: 20)
    |> validate_ability_scores()
  end

  defp validate_ability_scores(changeset) do
    Enum.reduce(
      ~w(strength dexterity constitution intelligence wisdom charisma)a,
      changeset,
      fn field, cs ->
        validate_number(cs, field, greater_than_or_equal_to: 1, less_than_or_equal_to: 30)
      end
    )
  end
end
