defmodule Gibbering.Repo.Migrations.CreateCampaignInvitations do
  use Ecto.Migration

  def change do
    create table(:campaign_invitations) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :character_id, references(:characters, on_delete: :nilify_all)
      add :initiated_by_id, references(:users, on_delete: :nilify_all)

      add :direction, :string, null: false
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create index(:campaign_invitations, [:campaign_id, :status])
    create index(:campaign_invitations, [:user_id, :status])
  end
end
