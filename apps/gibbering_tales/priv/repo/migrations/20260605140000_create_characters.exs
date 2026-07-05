defmodule Gibbering.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :race, :string, null: false
      add :class, :string, null: false
      add :level, :integer, null: false, default: 1
      add :alignment, :string, default: "true_neutral"
      add :background, :string

      add :strength, :integer, null: false, default: 10
      add :dexterity, :integer, null: false, default: 10
      add :constitution, :integer, null: false, default: 10
      add :intelligence, :integer, null: false, default: 10
      add :wisdom, :integer, null: false, default: 10
      add :charisma, :integer, null: false, default: 10

      add :skill_proficiencies, {:array, :string}, null: false, default: []
      add :saving_throw_proficiencies, {:array, :string}, null: false, default: []
      add :tool_proficiencies, {:array, :string}, null: false, default: []
      add :languages, {:array, :string}, null: false, default: []
      add :spells_known, {:array, :string}, null: false, default: []

      add :personality_traits, :text
      add :ideals, :text
      add :bonds, :text
      add :flaws, :text

      add :appearance, :map, null: false, default: %{}
      add :life_events, {:array, :map}, null: false, default: []
      add :starting_items, {:array, :map}, null: false, default: []

      timestamps()
    end

    create index(:characters, [:user_id])
  end
end
