defmodule Gibbering.Repo.Migrations.AddPresetKeyToEntities do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      add :preset_key, :string, null: true
    end
  end
end
