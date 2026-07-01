defmodule Gibbering.Repo.Migrations.CreateMonstersTable do
  use Ecto.Migration

  def change do
    create table(:monsters, primary_key: false) do
      add :key, :string, primary_key: true
      add :name, :string, null: false
      add :size, :string
      add :monster_type, :string
      add :alignment, :string
      add :armor_class, :integer
      add :hit_points, :integer
      add :hit_dice, :string
      add :speed, :map
      add :strength, :integer
      add :dexterity, :integer
      add :constitution, :integer
      add :intelligence, :integer
      add :wisdom, :integer
      add :charisma, :integer
      add :challenge_rating, :string
      add :xp_reward, :integer
      add :source_license, :string
      add :stat_block, :map

      timestamps()
    end

    create index(:monsters, [:monster_type])
    create index(:monsters, [:challenge_rating])
  end
end
