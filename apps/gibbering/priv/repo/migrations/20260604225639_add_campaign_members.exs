defmodule Gibbering.Repo.Migrations.AddCampaignMembers do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :dm_id, references(:users, on_delete: :nilify_all), null: true
    end

    create table(:campaign_members) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:campaign_members, [:campaign_id, :user_id])
    create index(:campaign_members, [:user_id])
  end
end
