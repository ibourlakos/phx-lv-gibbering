defmodule Gibbering.Repo.Migrations.CreateCatalogueTables do
  use Ecto.Migration

  def change do
    create table(:races, primary_key: false) do
      add :key, :string, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: false
      add :speed, :integer, null: false
      add :stat_bonuses, :map, null: false, default: %{}
      add :traits, {:array, :map}, null: false, default: []
      add :darkvision, :boolean, null: false, default: false

      timestamps()
    end

    create table(:classes, primary_key: false) do
      add :key, :string, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: false
      add :hit_die, :string, null: false
      add :base_hp, :integer, null: false
      add :primary_stats, {:array, :string}, null: false, default: []
      add :saving_throws, {:array, :string}, null: false, default: []
      add :armor_proficiencies, {:array, :string}, null: false, default: []
      add :weapon_proficiencies, {:array, :string}, null: false, default: []
      add :spellcasting, :boolean, null: false, default: false
      add :spells, {:array, :string}, null: false, default: []
      add :features, {:array, :map}, null: false, default: []
      add :stats, :map, null: false, default: %{}

      timestamps()
    end

    create table(:spells, primary_key: false) do
      add :key, :string, primary_key: true
      add :name, :string, null: false
      add :level, :integer, null: false
      add :school, :string, null: false
      add :casting_time, :string, null: false
      add :range, :string, null: false
      add :description, :text, null: false
      add :damage_dice, :string
      add :damage_type, :string
      add :attack_type, :string
      add :save, :string
      add :tags, {:array, :string}, null: false, default: []

      timestamps()
    end
  end
end
