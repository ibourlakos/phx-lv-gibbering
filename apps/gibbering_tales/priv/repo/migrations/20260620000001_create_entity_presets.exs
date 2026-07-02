defmodule Gibbering.Repo.Migrations.CreateEntityPresets do
  use Ecto.Migration

  def change do
    create table(:entity_presets, primary_key: false) do
      add :key, :string, primary_key: true
      add :name, :string, null: false
      add :entity_type, :string, null: false
      add :object_subtype, :string, null: true
      add :description, :string, null: true

      timestamps()
    end
  end
end
