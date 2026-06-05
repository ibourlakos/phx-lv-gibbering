defmodule Mix.Tasks.Gibbering.Ingest do
  use Mix.Task

  @shortdoc "Fetch SRD data from Open5e and seed the DB"
  @moduledoc """
  Fetches D&D 5e SRD data from the Open5e API (CC-BY-4.0) and upserts it
  into the catalogue tables.

  Currently ingests: monsters.

  ## Usage

      mix gibbering.ingest

  ## Options

      --dry-run   Fetch and parse without writing to DB

  ## Data source

  Open5e API — https://api.open5e.com
  License: CC-BY-4.0 (mirrors SRD 5.1 content)

  All entries are passed through `Gibbering.Pipeline.LegalGuard` before
  insertion. Entries containing WotC Product Identity terms are skipped.
  """

  require Logger

  alias Gibbering.{Repo, Pipeline.LegalGuard}
  alias Gibbering.Catalogue.Monster

  @open5e_base "https://api.open5e.com"
  @monsters_path "/monsters/"
  @srd_filter "document__slug=srd&limit=100"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    dry_run = "--dry-run" in args

    if dry_run, do: Mix.shell().info("Dry run — no DB writes")

    ingest_monsters(dry_run)
  end

  defp ingest_monsters(dry_run) do
    url = "#{@open5e_base}#{@monsters_path}?#{@srd_filter}"

    {inserted, skipped, blocked} = fetch_all_pages(url, {0, 0, 0}, dry_run)

    Mix.shell().info(
      "Monsters: #{inserted} inserted, #{skipped} skipped (already present), #{blocked} blocked (PI)"
    )
  end

  defp fetch_all_pages(nil, counts, _dry_run), do: counts

  defp fetch_all_pages(url, {ins, skip, block} = counts, dry_run) do
    Mix.shell().info("Fetching: #{url}")

    case Req.get(url, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} ->
        results = Map.get(body, "results", [])
        next_url = Map.get(body, "next")

        {new_ins, new_skip, new_block} =
          Enum.reduce(results, {ins, skip, block}, fn raw, {i, s, b} ->
            case process_monster(raw, dry_run) do
              :inserted -> {i + 1, s, b}
              :skipped -> {i, s + 1, b}
              :blocked -> {i, s, b + 1}
            end
          end)

        fetch_all_pages(next_url, {new_ins, new_skip, new_block}, dry_run)

      {:ok, %{status: status}} ->
        Mix.shell().error("Unexpected HTTP #{status} from Open5e — aborting")
        counts

      {:error, reason} ->
        Mix.shell().error("HTTP error: #{inspect(reason)} — aborting")
        counts
    end
  end

  defp process_monster(raw, dry_run) do
    name = Map.get(raw, "name", "")
    key = Map.get(raw, "slug", slugify(name))

    case LegalGuard.check(name) do
      {:error, reason} ->
        Logger.info("[LegalGuard] Skipping #{inspect(name)}: #{reason}")
        :blocked

      :ok ->
        if Repo.get(Monster, key) do
          :skipped
        else
          unless dry_run do
            attrs = normalize(raw, key)

            %Monster{}
            |> Monster.changeset(attrs)
            |> Repo.insert!(on_conflict: :nothing)
          end

          :inserted
        end
    end
  end

  defp normalize(raw, key) do
    %{
      key: key,
      name: raw["name"],
      size: raw["size"],
      monster_type: raw["type"],
      alignment: raw["alignment"],
      armor_class: parse_int(raw["armor_class"]),
      hit_points: parse_int(raw["hit_points"]),
      hit_dice: raw["hit_dice"],
      speed: raw["speed"],
      strength: parse_int(raw["strength"]),
      dexterity: parse_int(raw["dexterity"]),
      constitution: parse_int(raw["constitution"]),
      intelligence: parse_int(raw["intelligence"]),
      wisdom: parse_int(raw["wisdom"]),
      charisma: parse_int(raw["charisma"]),
      challenge_rating: to_string(raw["challenge_rating"] || ""),
      xp_reward: parse_int(raw["cr"]) || xp_from_cr(raw["challenge_rating"]),
      source_license: raw["document__license_url"] || "CC-BY-4.0",
      stat_block: %{
        "saving_throws" => raw["strength_save"] && build_saves(raw),
        "skills" => raw["skills"],
        "damage_immunities" => raw["damage_immunities"],
        "damage_resistances" => raw["damage_resistances"],
        "damage_vulnerabilities" => raw["damage_vulnerabilities"],
        "condition_immunities" => raw["condition_immunities"],
        "senses" => raw["senses"],
        "languages" => raw["languages"],
        "special_abilities" => raw["special_abilities"],
        "actions" => raw["actions"],
        "legendary_actions" => raw["legendary_actions"],
        "reactions" => raw["reactions"]
      }
    }
  end

  defp parse_int(nil), do: nil
  defp parse_int(n) when is_integer(n), do: n
  defp parse_int(s) when is_binary(s), do: String.to_integer(s)

  defp slugify(name), do: name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")

  defp build_saves(raw) do
    %{
      "strength" => raw["strength_save"],
      "dexterity" => raw["dexterity_save"],
      "constitution" => raw["constitution_save"],
      "intelligence" => raw["intelligence_save"],
      "wisdom" => raw["wisdom_save"],
      "charisma" => raw["charisma_save"]
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  # XP by CR from D&D 5e DMG table (SRD content)
  @cr_xp %{
    "0" => 10,
    "1/8" => 25,
    "1/4" => 50,
    "1/2" => 100,
    "1" => 200,
    "2" => 450,
    "3" => 700,
    "4" => 1100,
    "5" => 1800,
    "6" => 2300,
    "7" => 2900,
    "8" => 3900,
    "9" => 5000,
    "10" => 5900,
    "11" => 7200,
    "12" => 8400,
    "13" => 10_000,
    "14" => 11_500,
    "15" => 13_000,
    "16" => 15_000,
    "17" => 18_000,
    "18" => 20_000,
    "19" => 22_000,
    "20" => 25_000,
    "21" => 33_000,
    "22" => 41_000,
    "23" => 50_000,
    "24" => 62_000,
    "25" => 75_000,
    "26" => 90_000,
    "27" => 105_000,
    "28" => 120_000,
    "29" => 135_000,
    "30" => 155_000
  }

  defp xp_from_cr(cr), do: Map.get(@cr_xp, to_string(cr || ""))
end
