defmodule Gibbering.Admin do
  @moduledoc "Context for support user management and admin authentication."

  alias Gibbering.Repo
  alias Gibbering.Admin.SupportUser

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
end
