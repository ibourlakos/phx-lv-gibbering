defmodule Gibbering.Repo.Migrations.DropUsersRoleColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :role, :string
    end
  end
end
