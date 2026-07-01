defmodule GibberingWeb.DashboardLive do
  use GibberingWeb, :live_view

  alias Gibbering.Campaigns

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    entries = Campaigns.list_campaigns_for_user_with_characters(user.id)

    {:ok,
     socket
     |> assign(:entries, entries)
     |> assign(:current_user, user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 960px; margin: 0 auto; padding: 2rem;">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <h1 style="font-size: 1.8rem; color: #e8d5a0; font-family: serif;">My Campaigns</h1>
      </div>

      <div :if={@entries == []} style="text-align: center; color: #5a6070; padding: 4rem 0;">
        <p style="font-size: 1.1rem; margin-bottom: 1rem;">No campaigns yet.</p>
        <p style="font-size: 0.9rem;">
          Ask your DM for an invite link, or wait for an invite to arrive.
        </p>
      </div>

      <div style="display: flex; flex-direction: column; gap: 1.5rem;">
        <.campaign_card
          :for={{campaign, characters} <- @entries}
          campaign={campaign}
          characters={characters}
          current_user={@current_user}
        />
      </div>
    </div>
    """
  end

  defp campaign_card(assigns) do
    is_dm = assigns.campaign.dm_id == assigns.current_user.id
    assigns = assign(assigns, :is_dm, is_dm)

    ~H"""
    <div style="background: #1a1a2e; border: 1px solid #3a3a5a; border-radius: 8px; padding: 1.5rem;">
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem;">
        <div>
          <h2 style="color: #e8d5a0; font-family: serif; font-size: 1.3rem; margin-bottom: 0.3rem;">
            {@campaign.name}
          </h2>
          <div :if={@campaign.dm} style="color: #7a8090; font-size: 0.85rem;">
            DM: {@campaign.dm.username}
          </div>
        </div>
        <.status_badge status={@campaign.status} />
      </div>

      <div :if={@is_dm} style="display: flex; gap: 1rem; align-items: center; margin-top: 0.5rem;">
        <span style="color: #8090a8; font-size: 0.85rem; font-style: italic;">You are the DM</span>
        <a
          href={"/campaigns/#{@campaign.id}/prep"}
          style="background: #4a6fa5; color: white; padding: 0.4rem 1rem; border-radius: 4px; text-decoration: none; font-size: 0.9rem;"
        >
          Manage
        </a>
      </div>

      <div :if={not @is_dm}>
        <div
          :if={@characters == []}
          style="color: #5a6070; font-size: 0.85rem; font-style: italic; margin-top: 0.5rem;"
        >
          No characters in this campaign yet.
        </div>

        <div
          :if={@characters != []}
          style="display: flex; gap: 1rem; flex-wrap: wrap; margin-top: 0.5rem;"
        >
          <.character_card :for={cc <- @characters} cc={cc} campaign={@campaign} />
        </div>
      </div>
    </div>
    """
  end

  defp character_card(assigns) do
    char = assigns.cc.character
    assigns = assign(assigns, :char, char)

    ~H"""
    <div style="background: #0d0d1e; border: 1px solid #2a2a4a; border-radius: 6px; padding: 0.8rem; min-width: 160px;">
      <div style="color: #e8d5a0; font-weight: bold; font-size: 0.95rem;">{@char.name}</div>
      <div style="color: #a0a8b8; font-size: 0.8rem; margin-top: 0.2rem;">
        {String.capitalize(@char.race)} {String.capitalize(@char.class)}
      </div>
      <div style="color: #7a8090; font-size: 0.75rem;">Level {@char.level}</div>
      <a
        href={"/lobby/#{@campaign.id}"}
        style="display: block; margin-top: 0.6rem; color: #4a9a6a; font-size: 0.8rem; text-decoration: none;"
      >
        Enter lobby →
      </a>
    </div>
    """
  end

  defp status_badge(%{status: "lobby"} = assigns) do
    ~H"""
    <span style="background: #2a3a4a; color: #6a9ab8; font-size: 0.75rem; padding: 0.25rem 0.6rem; border-radius: 3px; border: 1px solid #3a5a6a;">
      Lobby
    </span>
    """
  end

  defp status_badge(%{status: "active"} = assigns) do
    ~H"""
    <span style="background: #1a3a1a; color: #6ab86a; font-size: 0.75rem; padding: 0.25rem 0.6rem; border-radius: 3px; border: 1px solid #3a6a3a;">
      Active
    </span>
    """
  end

  defp status_badge(%{status: "ended"} = assigns) do
    ~H"""
    <span style="background: #2a2a2a; color: #707070; font-size: 0.75rem; padding: 0.25rem 0.6rem; border-radius: 3px; border: 1px solid #3a3a3a;">
      Ended
    </span>
    """
  end

  defp status_badge(assigns) do
    ~H"""
    <span style="background: #2a2a2a; color: #707070; font-size: 0.75rem; padding: 0.25rem 0.6rem; border-radius: 3px; border: 1px solid #3a3a3a;">
      {@status}
    </span>
    """
  end
end
