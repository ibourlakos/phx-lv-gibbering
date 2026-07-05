defmodule Gibbering.Repo.Migrations.AddEdgesJsonbToMaps do
  use Ecto.Migration

  def change do
    alter table(:maps) do
      add :edges, :map, default: %{}
    end
  end
end
