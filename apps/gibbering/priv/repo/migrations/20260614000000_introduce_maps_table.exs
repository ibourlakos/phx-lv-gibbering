defmodule Gibbering.Repo.Migrations.IntroduceMapsTable do
  use Ecto.Migration

  def up do
    create table(:maps) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :x_extent, :integer, null: false
      add :y_extent, :integer, null: false
      add :tile_size, :integer, null: false
      timestamps()
    end

    create index(:maps, [:campaign_id])

    alter table(:campaigns) do
      add :active_map_id, references(:maps, on_delete: :nilify_all), null: true
    end

    alter table(:grid_tiles) do
      add :map_id, references(:maps, on_delete: :delete_all), null: true
    end

    execute """
    INSERT INTO maps (campaign_id, x_extent, y_extent, tile_size, inserted_at, updated_at)
    SELECT id, map_width, map_height, tile_size, NOW(), NOW()
    FROM campaigns
    """

    execute """
    UPDATE campaigns c
    SET active_map_id = m.id
    FROM maps m
    WHERE m.campaign_id = c.id
    """

    execute """
    UPDATE grid_tiles gt
    SET map_id = c.active_map_id
    FROM campaigns c
    WHERE gt.campaign_id = c.id
    """

    execute "ALTER TABLE grid_tiles ALTER COLUMN map_id SET NOT NULL"

    drop constraint(:grid_tiles, "grid_tiles_campaign_id_fkey")

    alter table(:grid_tiles) do
      remove :campaign_id
    end

    alter table(:campaigns) do
      remove :map_width
      remove :map_height
      remove :tile_size
    end
  end

  def down do
    alter table(:campaigns) do
      add :map_width, :integer, default: 10, null: false
      add :map_height, :integer, default: 10, null: false
      add :tile_size, :integer, default: 32, null: false
    end

    execute """
    UPDATE campaigns c
    SET map_width = m.x_extent,
        map_height = m.y_extent,
        tile_size = m.tile_size
    FROM maps m
    WHERE m.id = c.active_map_id
    """

    alter table(:grid_tiles) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: true
    end

    execute """
    UPDATE grid_tiles gt
    SET campaign_id = m.campaign_id
    FROM maps m
    WHERE m.id = gt.map_id
    """

    execute "ALTER TABLE grid_tiles ALTER COLUMN campaign_id SET NOT NULL"

    drop constraint(:grid_tiles, "grid_tiles_map_id_fkey")

    alter table(:grid_tiles) do
      remove :map_id
    end

    drop constraint(:campaigns, "campaigns_active_map_id_fkey")

    alter table(:campaigns) do
      remove :active_map_id
    end

    drop table(:maps)
  end
end
