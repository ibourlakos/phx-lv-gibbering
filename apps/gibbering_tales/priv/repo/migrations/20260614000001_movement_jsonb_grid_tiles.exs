defmodule Gibbering.Repo.Migrations.MovementJsonbGridTiles do
  use Ecto.Migration

  def up do
    alter table(:grid_tiles) do
      add :movement, :map, default: %{}
    end

    execute """
    UPDATE grid_tiles
    SET movement = CASE
      WHEN walkable THEN '{"walk":100,"fly":100}'::jsonb
      ELSE '{}'::jsonb
    END
    """

    alter table(:grid_tiles) do
      remove :walkable
    end
  end

  def down do
    alter table(:grid_tiles) do
      add :walkable, :boolean, default: true, null: false
    end

    execute """
    UPDATE grid_tiles
    SET walkable = CASE
      WHEN movement->>'walk' IS NOT NULL THEN true
      ELSE false
    END
    """

    alter table(:grid_tiles) do
      remove :movement
    end
  end
end
