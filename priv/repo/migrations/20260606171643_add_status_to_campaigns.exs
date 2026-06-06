defmodule Gibbering.Repo.Migrations.AddStatusToCampaigns do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :status, :string, null: false, default: "lobby"
    end
  end
end
