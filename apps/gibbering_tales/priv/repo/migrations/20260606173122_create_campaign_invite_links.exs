defmodule Gibbering.Repo.Migrations.CreateCampaignInviteLinks do
  use Ecto.Migration

  def change do
    create table(:campaign_invite_links) do
      add :token, :string, null: false
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :created_by_id, references(:users, on_delete: :delete_all), null: false
      add :expires_at, :utc_datetime, null: false
      add :uses_remaining, :integer
      add :revoked, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:campaign_invite_links, [:token])
    create index(:campaign_invite_links, [:campaign_id])
  end
end
