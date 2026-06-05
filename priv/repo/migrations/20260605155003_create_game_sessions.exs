defmodule Gibbering.Repo.Migrations.CreateGameSessions do
  use Ecto.Migration

  def change do
    create table(:game_sessions) do
      add :game_id, references(:campaigns, on_delete: :delete_all), null: false
      add :state, :binary, null: false

      timestamps()
    end

    create unique_index(:game_sessions, [:game_id])
  end
end
