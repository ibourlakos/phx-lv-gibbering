defmodule Gibbering.Repo.Migrations.CreateStyles do
  use Ecto.Migration

  def change do
    create table(:styles) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :description, :text

      timestamps()
    end

    create unique_index(:styles, [:slug])
  end
end
