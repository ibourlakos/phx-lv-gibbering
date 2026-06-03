defmodule Gibbering.Repo.Migrations.CreateGridTiles do
  use Ecto.Migration

  def change do
    create table(:grid_tiles) do
      add :x, :integer, null: false
      add :y, :integer, null: false
      add :texture, :string, null: false, default: "grass"
      add :walkable, :boolean, null: false, default: true
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
    end

    create index(:grid_tiles, [:campaign_id])
    create unique_index(:grid_tiles, [:campaign_id, :x, :y])
  end
end
