defmodule GibberingTales.CampaignInviteLinks do
  @moduledoc "Context for shareable campaign invite link tokens."

  import Ecto.Query

  alias GibberingTales.{Repo, CampaignInviteLink, Campaigns}

  @default_ttl_days 7

  @doc """
  Creates an invite link for a campaign.

  Options:
    - `:uses_remaining` — integer cap on redemptions (nil = unlimited)
    - `:ttl_days` — expiry window in days (default: #{@default_ttl_days})
  """
  def create_for_campaign(campaign_id, created_by_id, opts \\ []) do
    uses = Keyword.get(opts, :uses_remaining, nil)
    ttl = Keyword.get(opts, :ttl_days, @default_ttl_days)

    expires_at =
      DateTime.add(DateTime.utc_now(), ttl * 86_400, :second) |> DateTime.truncate(:second)

    %CampaignInviteLink{}
    |> CampaignInviteLink.create_changeset(%{
      campaign_id: campaign_id,
      created_by_id: created_by_id,
      expires_at: expires_at,
      uses_remaining: uses
    })
    |> Repo.insert()
  end

  @doc """
  Fetches an invite link by token, checking validity.

  Returns:
    - `{:ok, link}` — valid and active
    - `{:error, :not_found}` — token doesn't exist
    - `{:error, :expired}` — past `expires_at`
    - `{:error, :revoked}` — explicitly revoked
  """
  def get_by_token(token) do
    case Repo.get_by(CampaignInviteLink, token: token) do
      nil ->
        {:error, :not_found}

      %CampaignInviteLink{revoked: true} ->
        {:error, :revoked}

      %CampaignInviteLink{expires_at: expires_at} = link ->
        if DateTime.compare(expires_at, DateTime.utc_now()) == :lt do
          {:error, :expired}
        else
          {:ok, link}
        end
    end
  end

  @doc """
  Redeems an invite link for `user_id`, creating campaign membership.

  Returns `{:ok, link}` on success. Idempotent if user is already a member.
  Returns `{:error, :uses_exhausted}` if `uses_remaining` is 0.
  """
  def redeem(%CampaignInviteLink{uses_remaining: 0}, _user_id) do
    {:error, :uses_exhausted}
  end

  def redeem(%CampaignInviteLink{} = link, user_id) do
    {:ok, _} = Campaigns.join_campaign(link.campaign_id, user_id)

    updated =
      if link.uses_remaining != nil do
        link
        |> CampaignInviteLink.decrement_uses_changeset()
        |> Repo.update!()
      else
        link
      end

    {:ok, updated}
  end

  @doc "Revokes an invite link so it can no longer be used."
  def revoke(%CampaignInviteLink{} = link) do
    link
    |> CampaignInviteLink.revoke_changeset()
    |> Repo.update()
  end

  @doc """
  Returns the active (non-expired, non-revoked) invite link for a campaign, or `{:error, :none}`.
  """
  def active_for_campaign(campaign_id) do
    now = DateTime.utc_now()

    result =
      CampaignInviteLink
      |> where([l], l.campaign_id == ^campaign_id)
      |> where([l], l.revoked == false)
      |> where([l], l.expires_at > ^now)
      |> order_by([l], desc: l.inserted_at)
      |> limit(1)
      |> Repo.one()

    case result do
      nil -> {:error, :none}
      link -> {:ok, link}
    end
  end
end
