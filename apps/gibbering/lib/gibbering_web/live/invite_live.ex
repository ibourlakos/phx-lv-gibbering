defmodule GibberingWeb.InviteLive do
  use GibberingWeb, :live_view

  alias GibberingTales.Repo
  alias GibberingTales.{Campaign, CampaignInviteLinks}

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    user = socket.assigns.current_user

    {status, campaign} =
      case CampaignInviteLinks.get_by_token(token) do
        {:ok, link} ->
          campaign = Repo.get!(Campaign, link.campaign_id) |> Repo.preload(:dm)
          {:valid, {link, campaign}}

        {:error, reason} ->
          {reason, nil}
      end

    {:ok,
     socket
     |> assign(:token, token)
     |> assign(:status, status)
     |> assign(:campaign, elem_or_nil(campaign, 1))
     |> assign(:link, elem_or_nil(campaign, 0))
     |> assign(:current_user, user)}
  end

  @impl true
  def handle_event("join", _params, %{assigns: %{status: :valid}} = socket) do
    user = socket.assigns.current_user
    link = socket.assigns.link

    case CampaignInviteLinks.redeem(link, user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "You have joined #{socket.assigns.campaign.name}!")
         |> redirect(to: "/dashboard")}

      {:error, reason} ->
        {:noreply, assign(socket, :status, reason)}
    end
  end

  def handle_event("join", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 480px; margin: 4rem auto; padding: 2rem; text-align: center;">
      <.invite_body status={@status} campaign={@campaign} current_user={@current_user} />
    </div>
    """
  end

  defp invite_body(%{status: :valid} = assigns) do
    is_dm = assigns.campaign.dm_id == assigns.current_user.id
    assigns = assign(assigns, :is_dm, is_dm)

    ~H"""
    <div style="background: #1a1a2e; border: 1px solid #3a3a5a; border-radius: 8px; padding: 2rem;">
      <h1 style="color: #e8d5a0; font-family: serif; font-size: 1.6rem; margin-bottom: 0.5rem;">
        Campaign Invite
      </h1>
      <p style="color: #a0a8b8; margin-bottom: 1.5rem;">
        You have been invited to join:
      </p>
      <div style="background: #0d0d1e; border: 1px solid #2a2a4a; border-radius: 6px; padding: 1rem; margin-bottom: 1.5rem;">
        <div style="color: #e8d5a0; font-family: serif; font-size: 1.3rem; font-weight: bold;">
          {@campaign.name}
        </div>
        <div :if={@campaign.dm} style="color: #7a8090; font-size: 0.85rem; margin-top: 0.3rem;">
          DM: {@campaign.dm.username}
        </div>
      </div>

      <div :if={@is_dm} style="color: #7a8090; font-style: italic;">
        You are the DM of this campaign.
      </div>

      <div :if={not @is_dm} style="display: flex; gap: 1rem; justify-content: center;">
        <button
          phx-click="join"
          style="background: #2a6a3a; color: white; border: none; padding: 0.7rem 1.8rem; border-radius: 4px; cursor: pointer; font-size: 1rem;"
        >
          Join Campaign
        </button>
        <a
          href="/dashboard"
          style="background: #2a2a4a; color: #a0a8b8; border: 1px solid #4a4a6a; padding: 0.7rem 1.4rem; border-radius: 4px; text-decoration: none; font-size: 1rem;"
        >
          Decline
        </a>
      </div>
    </div>
    """
  end

  defp invite_body(%{status: :expired} = assigns) do
    ~H"""
    <div style="background: #1a1a2e; border: 1px solid #5a3a3a; border-radius: 8px; padding: 2rem;">
      <h1 style="color: #e07070; font-family: serif; font-size: 1.4rem; margin-bottom: 0.8rem;">
        Invite Expired
      </h1>
      <p style="color: #a0a8b8;">This invite link has expired. Ask your DM for a new one.</p>
    </div>
    """
  end

  defp invite_body(%{status: :revoked} = assigns) do
    ~H"""
    <div style="background: #1a1a2e; border: 1px solid #5a3a3a; border-radius: 8px; padding: 2rem;">
      <h1 style="color: #e07070; font-family: serif; font-size: 1.4rem; margin-bottom: 0.8rem;">
        Invite Revoked
      </h1>
      <p style="color: #a0a8b8;">This invite link has been revoked. Ask your DM for a new one.</p>
    </div>
    """
  end

  defp invite_body(%{status: :not_found} = assigns) do
    ~H"""
    <div style="background: #1a1a2e; border: 1px solid #5a3a3a; border-radius: 8px; padding: 2rem;">
      <h1 style="color: #e07070; font-family: serif; font-size: 1.4rem; margin-bottom: 0.8rem;">
        Invalid Invite
      </h1>
      <p style="color: #a0a8b8;">This invite link was not found. Check the URL and try again.</p>
    </div>
    """
  end

  defp invite_body(%{status: :uses_exhausted} = assigns) do
    ~H"""
    <div style="background: #1a1a2e; border: 1px solid #5a3a3a; border-radius: 8px; padding: 2rem;">
      <h1 style="color: #e07070; font-family: serif; font-size: 1.4rem; margin-bottom: 0.8rem;">
        Invite Full
      </h1>
      <p style="color: #a0a8b8;">
        This invite link has reached its maximum number of uses. Ask your DM for a new one.
      </p>
    </div>
    """
  end

  defp invite_body(assigns) do
    ~H"""
    <div style="background: #1a1a2e; border: 1px solid #5a3a3a; border-radius: 8px; padding: 2rem;">
      <h1 style="color: #e07070; font-family: serif; font-size: 1.4rem; margin-bottom: 0.8rem;">
        Something went wrong
      </h1>
      <p style="color: #a0a8b8;">This invite link is not available.</p>
    </div>
    """
  end

  defp elem_or_nil(nil, _), do: nil
  defp elem_or_nil(tuple, index), do: elem(tuple, index)
end
