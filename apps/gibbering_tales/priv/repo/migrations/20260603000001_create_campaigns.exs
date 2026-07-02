defmodule Gibbering.Repo.Migrations.CreateCampaigns do
  use Ecto.Migration

  def change do
    create table(:campaigns) do
      add :name, :string, null: false
      add :map_width, :integer, null: false, default: 10
      add :map_height, :integer, null: false, default: 10
      add :tile_size, :integer, null: false, default: 32

      timestamps()
    end
  end
end
