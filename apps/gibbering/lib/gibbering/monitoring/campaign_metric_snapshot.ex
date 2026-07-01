defmodule Gibbering.Monitoring.CampaignMetricSnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "campaign_metric_snapshots" do
    field :campaign_id, :integer
    field :metric, :string
    field :value, :float
    field :recorded_at, :utc_datetime

    timestamps(updated_at: false)
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [:campaign_id, :metric, :value, :recorded_at])
    |> validate_required([:campaign_id, :metric, :value, :recorded_at])
  end
end
