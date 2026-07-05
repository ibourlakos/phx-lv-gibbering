defmodule GibberingTales.Engine.GameSession do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "game_sessions" do
    field :game_id, :integer
    field :state, :binary

    timestamps()
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [:game_id, :state])
    |> validate_required([:game_id, :state])
    |> unique_constraint(:game_id)
  end
end
