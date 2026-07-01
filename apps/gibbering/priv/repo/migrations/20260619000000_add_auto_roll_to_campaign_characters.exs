defmodule Gibbering.Repo.Migrations.AddAutoRollToCampaignCharacters do
  use Ecto.Migration

  def change do
    alter table(:campaign_characters) do
      add :auto_roll, :boolean, null: false, default: true
    end
  end
end
