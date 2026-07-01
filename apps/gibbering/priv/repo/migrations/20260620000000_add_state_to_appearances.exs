defmodule Gibbering.Repo.Migrations.AddStateToAppearances do
  use Ecto.Migration

  def change do
    alter table(:appearances) do
      add :state, :string, null: false, default: "default"
    end

    drop unique_index(:appearances, [:style_id, :content_type, :content_key])
    create unique_index(:appearances, [:style_id, :content_type, :content_key, :state])
  end
end
