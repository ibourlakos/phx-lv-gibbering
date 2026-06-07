defmodule Gibbering.Repo.Migrations.CreateAppearances do
  use Ecto.Migration

  def change do
    create table(:appearances) do
      add :style_id, references(:styles, on_delete: :delete_all), null: false
      add :content_type, :string, null: false
      add :content_key, :string, null: false
      add :data, :map, null: false, default: %{}

      timestamps()
    end

    create unique_index(:appearances, [:style_id, :content_type, :content_key])
    create index(:appearances, [:style_id])
  end
end
