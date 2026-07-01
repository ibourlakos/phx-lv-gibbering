defmodule GibberingTales.Pipeline.LegalGuard do
  @moduledoc """
  Filters WotC Product Identity terms from ingested SRD data.

  PI terms are proper nouns (setting names, named characters, specific deities)
  that WotC has reserved outside the SRD CC-BY-4.0 grant. Matching entries are
  rejected at ingest time with a reason logged.

  This module only covers the PI blacklist. Expansion to source-license tagging
  and attribution flags is tracked in docs/issues/008's LegalGuard section.
  """

  # WotC Product Identity — setting names, named characters, named deities
  # Source: WotC Fan Content Policy + SRD 5.1 introductory PI notice
  @pi_terms ~w(
    forgotten\ realms forgotten_realms
    dragonlance
    eberron
    greyhawk
    ravenloft
    dark\ sun dark_sun
    spelljammer
    planescape
    birthright
    mystara
    drizzt elminster mordenkainen volo acererak strahd
    baldur waterdeep neverwinter amn
    al-qadim
  )

  @doc """
  Returns `{:ok, entity}` if the entity name is free of Product Identity terms,
  or `{:error, reason}` if a PI term is detected.
  """
  def check(entity_name) when is_binary(entity_name) do
    lower = String.downcase(entity_name)

    case Enum.find(@pi_terms, &String.contains?(lower, &1)) do
      nil -> :ok
      term -> {:error, "contains WotC Product Identity term: #{inspect(term)}"}
    end
  end

  @doc "Returns true when the entity name passes the PI check."
  def safe?(entity_name), do: check(entity_name) == :ok
end
