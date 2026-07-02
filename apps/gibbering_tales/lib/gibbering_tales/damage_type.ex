defmodule GibberingTales.DamageType do
  @valid ~w(acid bludgeoning cold fire force lightning necrotic piercing poison
            psychic radiant slashing thunder)a

  @doc """
  Casts a string to a known SRD damage type atom.
  Returns `{:ok, atom}` for valid types, `{:error, :unknown}` otherwise.
  """
  def cast(string) when is_binary(string) do
    atom = String.to_atom(string)
    if atom in @valid, do: {:ok, atom}, else: {:error, :unknown}
  end

  @doc "Returns all valid SRD damage type atoms."
  def all, do: @valid
end
