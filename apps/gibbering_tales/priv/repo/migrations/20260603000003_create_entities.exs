defmodule Gibbering.Repo.Migrations.CreateEntities do
  use Ecto.Migration

  def change do
    create table(:entities) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :sprite, :string, null: false
      add :x, :integer, null: false
      add :y, :integer, null: false
      add :hp, :integer, null: false
      add :max_hp, :integer, null: false
      add :tags, {:array, :string}, null: false, default: []
      add :stats, :map, null: false, default: %{}
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:entities, [:campaign_id])
  end
end
