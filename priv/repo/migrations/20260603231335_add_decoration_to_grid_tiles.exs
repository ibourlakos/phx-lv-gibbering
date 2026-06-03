defmodule Gibbering.Repo.Migrations.AddDecorationToGridTiles do
  use Ecto.Migration

  def change do
    alter table(:grid_tiles) do
      add :decoration, :string, default: nil
    end
  end
end
