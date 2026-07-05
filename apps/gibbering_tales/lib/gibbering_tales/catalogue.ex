defmodule GibberingTales.Catalogue do
  import Ecto.Query
  alias GibberingTales.Repo
  alias GibberingTales.Catalogue.{Race, Class, Spell, Monster, EntityPreset, Style, Appearance}

  def list_races, do: Repo.all(from r in Race, order_by: r.key)
  def list_classes, do: Repo.all(from c in Class, order_by: c.key)
  def list_spells, do: Repo.all(from s in Spell, order_by: s.key)
  def list_monsters, do: Repo.all(from m in Monster, order_by: m.name)

  def get_race(key), do: Repo.get(Race, key)
  def get_class(key), do: Repo.get(Class, key)
  def get_spell(key), do: Repo.get(Spell, key)
  def get_monster(key), do: Repo.get(Monster, key)

  def list_entity_presets, do: Repo.all(from p in EntityPreset, order_by: p.key)

  def get_entity_preset(key), do: Repo.get(EntityPreset, key)

  # Returns %{key => %EntityPreset{}} for all presets — used at scene load to populate
  # object_subtype on engine entities without per-entity DB queries.
  def entity_presets_map do
    list_entity_presets() |> Map.new(fn p -> {p.key, p} end)
  end

  def default_style_slug, do: "dst"

  # Returns %{{"content_type", "content_key", "state"} => data} for the given style slug.
  # The state key is always present; "default" means the base appearance.
  # Unknown slugs return an empty map; callers must supply their own fallback values.
  def appearances_for_style(style_slug) do
    from(a in Appearance,
      join: s in Style,
      on: s.id == a.style_id,
      where: s.slug == ^style_slug,
      select: {a.content_type, a.content_key, a.state, a.data}
    )
    |> Repo.all()
    |> Map.new(fn {type, key, state, data} -> {{type, key, state}, data} end)
  end
end
