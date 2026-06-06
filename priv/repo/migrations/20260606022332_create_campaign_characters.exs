defmodule Gibbering.Repo.Migrations.CreateCampaignCharacters do
  use Ecto.Migration

  def change do
    create table(:campaign_characters) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :owner_id, references(:users, on_delete: :delete_all), null: false
      add :controller_id, references(:users, on_delete: :nilify_all)

      add :active, :boolean, default: false, null: false

      add :override_level, :integer
      add :override_ability_scores, :map
      add :override_background_key, :string
      add :override_starting_items, {:array, :map}, default: []
      add :override_bonus_proficiencies, {:array, :string}, default: []

      add :dm_life_events, {:array, :map}, default: []
      add :campaign_relations, {:array, :map}, default: []

      timestamps()
    end

    create index(:campaign_characters, [:campaign_id])
    create index(:campaign_characters, [:character_id])
  end
end
