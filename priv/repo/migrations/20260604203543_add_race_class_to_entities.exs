defmodule Gibbering.Repo.Migrations.AddRaceClassToEntities do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      add :race, :string, default: "human"
      add :class, :string, default: "fighter"
    end
  end
end
