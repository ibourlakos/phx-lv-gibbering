defmodule Gibbering.Characters do
  import Ecto.Query

  alias Gibbering.{Repo, Character}

  def list_for_user(user_id) do
    Character
    |> where(user_id: ^user_id)
    |> order_by(:name)
    |> Repo.all()
  end

  def get_character!(user_id, id) do
    Character
    |> where(user_id: ^user_id, id: ^id)
    |> Repo.one!()
  end

  def create_character(user_id, attrs) do
    %Character{user_id: user_id}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  def update_character(%Character{} = character, attrs) do
    character
    |> Character.changeset(attrs)
    |> Repo.update()
  end

  def delete_character(user_id, id) do
    character = get_character!(user_id, id)
    Repo.delete(character)
  end
end
