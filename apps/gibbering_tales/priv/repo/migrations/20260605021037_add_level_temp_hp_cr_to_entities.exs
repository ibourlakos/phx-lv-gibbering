defmodule Gibbering.Repo.Migrations.AddLevelTempHpCrToEntities do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      add :level, :integer, null: false, default: 1
      add :temp_hp, :integer, null: false, default: 0
      add :challenge_rating, :decimal, null: true
      add :xp_reward, :integer, null: true
    end
  end
end
