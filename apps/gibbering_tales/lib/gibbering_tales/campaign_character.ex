defmodule GibberingTales.CampaignCharacter do
  @moduledoc "DM-adjusted instance of a `Character` template within a specific campaign."

  use Ecto.Schema
  import Ecto.Changeset

  schema "campaign_characters" do
    belongs_to :campaign, GibberingTales.Campaign
    belongs_to :character, GibberingTales.Character
    belongs_to :owner, GibberingTales.Accounts.User
    belongs_to :controller, GibberingTales.Accounts.User

    field :active, :boolean, default: false
    field :auto_roll, :boolean, default: true

    field :override_level, :integer
    field :override_ability_scores, :map
    field :override_background_key, :string
    field :override_starting_items, {:array, :map}, default: []
    field :override_bonus_proficiencies, {:array, :string}, default: []

    field :dm_life_events, {:array, :map}, default: []
    field :campaign_relations, {:array, :map}, default: []

    timestamps()
  end

  @doc "Changeset for creating a new campaign character."
  def create_changeset(campaign_character, attrs) do
    campaign_character
    |> cast(attrs, [:campaign_id, :character_id, :owner_id, :controller_id])
    |> validate_required([:campaign_id, :character_id, :owner_id])
    |> put_default_controller()
    |> foreign_key_constraint(:campaign_id)
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:owner_id)
    |> foreign_key_constraint(:controller_id)
  end

  @doc "Changeset for updating auto-roll preference."
  def auto_roll_changeset(campaign_character, attrs) do
    campaign_character
    |> cast(attrs, [:auto_roll])
    |> validate_required([:auto_roll])
  end

  @doc "Changeset for DM updates: active flag, controller reassignment, and override fields."
  def update_changeset(campaign_character, attrs) do
    campaign_character
    |> cast(attrs, [
      :active,
      :controller_id,
      :override_level,
      :override_ability_scores,
      :override_background_key,
      :override_starting_items,
      :override_bonus_proficiencies,
      :dm_life_events,
      :campaign_relations
    ])
    |> foreign_key_constraint(:controller_id)
  end

  defp put_default_controller(changeset) do
    case get_field(changeset, :controller_id) do
      nil -> put_change(changeset, :controller_id, get_field(changeset, :owner_id))
      _ -> changeset
    end
  end
end
