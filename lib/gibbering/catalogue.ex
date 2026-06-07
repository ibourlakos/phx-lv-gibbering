defmodule Gibbering.Catalogue do
  import Ecto.Query
  alias Gibbering.Repo
  alias Gibbering.Catalogue.{Race, Class, Spell, Monster, Style, Appearance}

  def list_races, do: Repo.all(from r in Race, order_by: r.key)
  def list_classes, do: Repo.all(from c in Class, order_by: c.key)
  def list_spells, do: Repo.all(from s in Spell, order_by: s.key)
  def list_monsters, do: Repo.all(from m in Monster, order_by: m.name)

  def get_race(key), do: Repo.get(Race, key)
  def get_class(key), do: Repo.get(Class, key)
  def get_spell(key), do: Repo.get(Spell, key)
  def get_monster(key), do: Repo.get(Monster, key)

  def default_style_slug, do: "dst"

  # Returns %{{"content_type", "content_key"} => %{"field" => value}} for the given style slug.
  # Unknown slugs return an empty map; callers must supply their own fallback values.
  def appearances_for_style(style_slug) do
    from(a in Appearance,
      join: s in Style,
      on: s.id == a.style_id,
      where: s.slug == ^style_slug,
      select: {a.content_type, a.content_key, a.data}
    )
    |> Repo.all()
    |> Map.new(fn {type, key, data} -> {{type, key}, data} end)
  end
end
