defmodule GibberingTalesAdmin.Admin.SupportUser do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(viewer moderator editor admin)

  schema "support_users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :role, :string, default: "viewer"

    timestamps()
  end

  def changeset(support_user, attrs) do
    support_user
    |> cast(attrs, [:email, :password, :role])
    |> validate_required([:email, :password, :role])
    |> validate_format(:email, ~r/@/, message: "must contain @")
    |> validate_length(:password, min: 8, max: 72)
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:email)
    |> hash_password()
  end

  def update_changeset(support_user, attrs) do
    support_user
    |> cast(attrs, [:role])
    |> validate_inclusion(:role, @roles)
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    put_change(cs, :hashed_password, Pbkdf2.hash_pwd_salt(pw))
  end

  defp hash_password(cs), do: cs
end
