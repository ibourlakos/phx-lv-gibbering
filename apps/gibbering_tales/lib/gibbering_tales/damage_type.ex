defmodule GibberingTales.DamageType do
  @valid ~w(acid bludgeoning cold fire force lightning necrotic piercing poison
            psychic radiant slashing thunder)a

  @lookup Map.new(@valid, &{Atom.to_string(&1), &1})

  @doc """
  Casts a string to a known SRD damage type atom.
  Returns `{:ok, atom}` for valid types, `{:error, :unknown}` otherwise.
  """
  def cast(string) when is_binary(string) do
    case @lookup do
      %{^string => atom} -> {:ok, atom}
      _ -> {:error, :unknown}
    end
  end

  @doc "Returns all valid SRD damage type atoms."
  def all, do: @valid
end
