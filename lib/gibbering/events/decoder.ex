defmodule Gibbering.Events.Decoder do
  @moduledoc """
  Decodes raw string-keyed maps (as deserialized from the event log) into typed
  event structs. Applies the `Gibbering.Events.Upcaster` chain so that events
  persisted at an older schema version are transparently transformed before
  struct construction.

  Used exclusively at the event log boundary — in-process events are already
  typed structs and need no decoding.
  """

  @doc """
  Decodes a raw string-keyed map into the given event struct module.

  Steps:
  1. Read `schema_version` from the map (defaults to `1` when absent).
  2. Apply `module.upcast/2` for each version step from `stored_version` up to
     `module.current_version() - 1`, transforming the map incrementally.
  3. Atomise string keys and construct the struct, setting `schema_version` to
     the module's current version.

  Returns `{:ok, struct}` or `{:error, reason}`.
  """
  @spec decode(module(), map()) :: {:ok, struct()} | {:error, term()}
  def decode(module, raw_map) when is_map(raw_map) do
    stored = Map.get(raw_map, "schema_version", 1)
    current = module.current_version()

    if stored > current do
      {:error, {:schema_version_too_new, stored, current}}
    else
      upcasted =
        Enum.reduce(stored..(current - 1)//1, raw_map, fn v, acc ->
          module.upcast(v, acc)
        end)

      atomised =
        Map.new(upcasted, fn {k, v} ->
          {String.to_existing_atom(k), v}
        end)

      {:ok, struct!(module, Map.put(atomised, :schema_version, current))}
    end
  rescue
    e -> {:error, e}
  end
end
