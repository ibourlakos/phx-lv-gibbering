defmodule Gibbering.Repo.Migrations.CreateCampaignMetricSnapshots do
  use Ecto.Migration

  def change do
    create table(:campaign_metric_snapshots, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :campaign_id, :integer, null: false
      add :metric, :string, size: 64, null: false
      add :value, :float, null: false
      add :recorded_at, :utc_datetime, null: false

      timestamps(updated_at: false)
    end

    create index(:campaign_metric_snapshots, [:campaign_id, :metric, :recorded_at])
    create index(:campaign_metric_snapshots, [:recorded_at])
  end
end
