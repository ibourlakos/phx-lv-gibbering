defmodule GibberingTalesAdmin.Repo.Migrations.CreateSupportUsers do
  use Ecto.Migration

  def change do
    create table(:support_users) do
      add :email, :string, null: false
      add :hashed_password, :string, null: false
      add :role, :string, null: false, default: "viewer"

      timestamps()
    end

    create unique_index(:support_users, [:email])
  end
end
