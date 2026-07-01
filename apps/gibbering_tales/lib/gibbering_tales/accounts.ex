defmodule GibberingTales.Accounts do
  alias GibberingTales.Repo
  alias GibberingTales.Accounts.User

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def authenticate_user(username, password) do
    user = Repo.get_by(User, username: username)

    cond do
      user && Pbkdf2.verify_pass(password, user.password_hash) && user.suspended_at != nil ->
        {:error, :suspended}

      user && Pbkdf2.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        Pbkdf2.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def get_user_by_id(id), do: Repo.get(User, id)

  def get_user_by_username(username), do: Repo.get_by(User, username: username)
end
