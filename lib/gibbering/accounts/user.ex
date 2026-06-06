defmodule Gibbering.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :suspended_at, :utc_datetime

    has_many :campaign_members, Gibbering.CampaignMember

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username, :password])
    |> validate_length(:username, min: 3, max: 20)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/,
      message: "only letters, numbers, underscores"
    )
    |> validate_length(:password, min: 6, max: 72)
    |> unique_constraint(:username)
    |> hash_password()
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    put_change(cs, :password_hash, Pbkdf2.hash_pwd_salt(pw))
  end

  defp hash_password(cs), do: cs
end
