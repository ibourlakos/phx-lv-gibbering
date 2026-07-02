defmodule Gibbering.Repo.Migrations.AddSuspendedAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :suspended_at, :utc_datetime
    end
  end
end
