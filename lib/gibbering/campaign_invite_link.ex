defmodule Gibbering.CampaignInviteLink do
  @moduledoc "A shareable token link that grants campaign membership on redemption."

  use Ecto.Schema
  import Ecto.Changeset

  schema "campaign_invite_links" do
    field :token, :string
    field :expires_at, :utc_datetime
    field :uses_remaining, :integer
    field :revoked, :boolean, default: false

    belongs_to :campaign, Gibbering.Campaign
    belongs_to :created_by, Gibbering.Accounts.User

    timestamps()
  end

  def create_changeset(link, attrs) do
    link
    |> cast(attrs, [:campaign_id, :created_by_id, :expires_at, :uses_remaining])
    |> validate_required([:campaign_id, :created_by_id, :expires_at])
    |> put_token()
    |> foreign_key_constraint(:campaign_id)
    |> foreign_key_constraint(:created_by_id)
    |> unique_constraint(:token)
  end

  def revoke_changeset(link) do
    change(link, revoked: true)
  end

  def decrement_uses_changeset(link) do
    change(link, uses_remaining: link.uses_remaining - 1)
  end

  defp put_token(changeset) do
    put_change(changeset, :token, generate_token())
  end

  defp generate_token do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
