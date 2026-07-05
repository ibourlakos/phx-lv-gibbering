defmodule GibberingTales.Catalogue.Cache do
  use GenServer

  alias GibberingTales.Catalogue

  @races_table :catalogue_races
  @classes_table :catalogue_classes
  @spells_table :catalogue_spells
  @monsters_table :catalogue_monsters

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    for t <- [@races_table, @classes_table, @spells_table, @monsters_table] do
      :ets.new(t, [:named_table, :set, :protected, read_concurrency: true])
    end

    load()
    {:ok, :loaded}
  end

  # ---------------------------------------------------------------------------
  # Public reads — bypass GenServer, read ETS directly
  # ---------------------------------------------------------------------------

  def get_race(key) do
    case :ets.lookup(@races_table, key) do
      [{_, race}] -> race
      [] -> nil
    end
  end

  def get_class(key) do
    case :ets.lookup(@classes_table, key) do
      [{_, cls}] -> cls
      [] -> nil
    end
  end

  def get_spell(key) do
    case :ets.lookup(@spells_table, key) do
      [{_, spell}] -> spell
      [] -> nil
    end
  end

  def get_monster(key) do
    case :ets.lookup(@monsters_table, key) do
      [{_, m}] -> m
      [] -> nil
    end
  end

  def list_races, do: :ets.tab2list(@races_table) |> Enum.map(&elem(&1, 1))
  def list_classes, do: :ets.tab2list(@classes_table) |> Enum.map(&elem(&1, 1))
  def list_spells, do: :ets.tab2list(@spells_table) |> Enum.map(&elem(&1, 1))
  def list_monsters, do: :ets.tab2list(@monsters_table) |> Enum.map(&elem(&1, 1))

  def races_map, do: list_races() |> Map.new(&{&1.key, &1})
  def classes_map, do: list_classes() |> Map.new(&{&1.key, &1})

  def reload!, do: GenServer.call(__MODULE__, :reload)

  def handle_call(:reload, _from, state) do
    load()
    {:reply, :ok, state}
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp load do
    for race <- Catalogue.list_races() do
      :ets.insert(@races_table, {race.key, race})
    end

    for cls <- Catalogue.list_classes() do
      :ets.insert(@classes_table, {cls.key, cls})
    end

    for spell <- Catalogue.list_spells() do
      :ets.insert(@spells_table, {spell.key, spell})
    end

    for monster <- Catalogue.list_monsters() do
      :ets.insert(@monsters_table, {monster.key, monster})
    end
  end
end
