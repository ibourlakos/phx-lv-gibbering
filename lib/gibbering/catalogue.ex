defmodule Gibbering.Catalogue do
  import Ecto.Query
  alias Gibbering.Repo
  alias Gibbering.Catalogue.{Race, Class, Spell, Monster}

  def list_races, do: Repo.all(from r in Race, order_by: r.key)
  def list_classes, do: Repo.all(from c in Class, order_by: c.key)
  def list_spells, do: Repo.all(from s in Spell, order_by: s.key)
  def list_monsters, do: Repo.all(from m in Monster, order_by: m.name)

  def get_race(key), do: Repo.get(Race, key)
  def get_class(key), do: Repo.get(Class, key)
  def get_spell(key), do: Repo.get(Spell, key)
  def get_monster(key), do: Repo.get(Monster, key)
end
