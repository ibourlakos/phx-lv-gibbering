defmodule Gibbering.Admin do
  @moduledoc "Context for support user management and admin authentication."

  import Ecto.Query

  alias Gibbering.Repo
  alias Gibbering.Admin.{SupportUser, AuditLog}
  alias Gibbering.Accounts.User
  alias Gibbering.Campaign

  @doc "Creates a support user. Returns `{:ok, user}` or `{:error, changeset}`."
  def create_support_user(attrs) do
    %SupportUser{}
    |> SupportUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Returns a changeset for updating a support user's mutable fields."
  def change_support_user(%SupportUser{} = user, attrs \\ %{}) do
    SupportUser.update_changeset(user, attrs)
  end

  @doc "Authenticates by email and password. Returns `{:ok, user}` or `{:error, :invalid_credentials}`."
  def authenticate_support_user(email, password) do
    user = Repo.get_by(SupportUser, email: email)

    cond do
      user && Pbkdf2.verify_pass(password, user.hashed_password) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        Pbkdf2.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc "Fetches a support user by id. Returns `nil` if not found."
  def get_support_user_by_id(id), do: Repo.get(SupportUser, id)

  @doc """
  Inserts an immutable audit log entry. `opts` may include `metadata: map`.
  Returns `{:ok, entry}` or `{:error, changeset}`.
  """
  def log_action(actor_id, action, target_type, target_id, opts \\ []) do
    %AuditLog{}
    |> AuditLog.changeset(%{
      actor_id: actor_id,
      action: action,
      target_type: target_type,
      target_id: to_string(target_id),
      metadata: Keyword.get(opts, :metadata)
    })
    |> Repo.insert()
  end

  @doc """
  Returns audit log entries in descending order.
  Accepts filter opts: `actor_id:`, `action:`.
  """
  def list_audit_log(opts \\ []) do
    base = from l in AuditLog, order_by: [desc: l.inserted_at], preload: [:actor]

    base
    |> maybe_filter_actor(Keyword.get(opts, :actor_id))
    |> maybe_filter_action(Keyword.get(opts, :action))
    |> Repo.all()
  end

  defp maybe_filter_actor(q, nil), do: q
  defp maybe_filter_actor(q, id), do: where(q, [l], l.actor_id == ^id)

  defp maybe_filter_action(q, nil), do: q
  defp maybe_filter_action(q, action), do: where(q, [l], l.action == ^action)

  # ---------------------------------------------------------------------------
  # User admin operations
  # ---------------------------------------------------------------------------

  @doc "Returns all users, optionally filtered by username substring search."
  def list_users(opts \\ []) do
    base = from u in User, order_by: [asc: u.username]

    base
    |> maybe_search_username(Keyword.get(opts, :search))
    |> Repo.all()
  end

  @doc "Returns user with campaign_members preloaded, or nil."
  def get_user_with_memberships(id) do
    User
    |> preload(:campaign_members)
    |> Repo.get(id)
  end

  @doc "Sets suspended_at on the user and logs the action. Returns `{:ok, user}`."
  def suspend_user(actor_id, user_id) do
    user = Repo.get!(User, user_id)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok, updated} =
      user
      |> Ecto.Changeset.change(suspended_at: now)
      |> Repo.update()

    log_action(actor_id, "user.suspend", "user", user_id)
    {:ok, updated}
  end

  @doc "Clears suspended_at on the user and logs the action. Returns `{:ok, user}`."
  def unsuspend_user(actor_id, user_id) do
    user = Repo.get!(User, user_id)

    {:ok, updated} =
      user
      |> Ecto.Changeset.change(suspended_at: nil)
      |> Repo.update()

    log_action(actor_id, "user.unsuspend", "user", user_id)
    {:ok, updated}
  end

  defp maybe_search_username(q, nil), do: q
  defp maybe_search_username(q, ""), do: q

  defp maybe_search_username(q, term),
    do: where(q, [u], ilike(u.username, ^"%#{term}%"))

  # ---------------------------------------------------------------------------
  # Campaign admin operations
  # ---------------------------------------------------------------------------

  @doc "Returns all campaigns ordered by id, with dm preloaded."
  def list_all_campaigns do
    Campaign
    |> order_by([c], desc: c.id)
    |> preload(:dm)
    |> Repo.all()
  end

  @doc "Returns campaign with dm and campaign_members (with user) preloaded, or nil."
  def get_campaign_with_members(id) do
    Campaign
    |> preload([:dm, campaign_members: :user])
    |> Repo.get(id)
  end

  @doc """
  Force-closes a campaign: sets status to \"ended\", terminates any running SceneServer,
  and logs the action. Returns `{:ok, campaign}` or `{:error, :not_found}`.
  """
  def force_close_campaign(actor_id, campaign_id, reason) do
    case Repo.get(Campaign, campaign_id) do
      nil ->
        {:error, :not_found}

      campaign ->
        {:ok, updated} =
          campaign
          |> Campaign.changeset(%{status: "ended"})
          |> Repo.update()

        maybe_terminate_scene_server(campaign_id)

        log_action(actor_id, "campaign.force_close", "campaign", campaign_id,
          metadata: %{"reason" => reason}
        )

        {:ok, updated}
    end
  end

  defp maybe_terminate_scene_server(campaign_id) do
    case Registry.lookup(Gibbering.GameRegistry, campaign_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(Gibbering.SceneSupervisor, pid)
      [] -> :ok
    end
  end
end
