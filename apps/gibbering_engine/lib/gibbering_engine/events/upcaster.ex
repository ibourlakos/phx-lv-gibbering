defmodule GibberingEngine.Events.Upcaster do
  @moduledoc """
  Behaviour implemented by every event struct module in `GibberingEngine.Events`.

  The decoder chains `upcast/2` calls from the persisted `schema_version` up to
  the module's `current_version/0` when reading events from the event log.
  At v1 all implementations are identity functions — the infrastructure is in
  place for when a field is added and a version bump is needed.
  """

  @doc "Returns the module's current schema version integer."
  @callback current_version() :: pos_integer()

  @doc """
  Transforms a raw map from `from_version` format to `from_version + 1` format.
  Called by `GibberingEngine.Events.Decoder` for each version step during upcasting.
  The raw map has string keys (as deserialized from the event log).
  """
  @callback upcast(from_version :: pos_integer(), raw_map :: map()) :: map()
end
