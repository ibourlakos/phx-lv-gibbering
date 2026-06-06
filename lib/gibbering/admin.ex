defmodule Gibbering.Admin do
  @moduledoc "Context for support user management and admin authentication."

  import Ecto.Query

  alias Gibbering.Repo
  alias Gibbering.Admin.{SupportUser, AuditLog}

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
end
