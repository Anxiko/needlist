defmodule Needlist.Discogs.Model.Format do
  require Logger
  @keys [:name, :qty, :descriptions]

  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          name: String.t(),
          qty: non_neg_integer(),
          descriptions: [String.t()]
        }

  import Needlist.Discogs.Guards
  alias Needlist.Discogs.Parsing

  @spec parse(map()) :: {:ok, t()} | :error
  def parse(%{"name" => name, "qty" => qty, "descriptions" => descriptions})
      when is_binary(name) and is_integer_or_raw(qty) and is_list(descriptions) do
    with {:ok, qty} when qty >= 0 <- Parsing.parse_integer(qty) do
      {:ok, %__MODULE__{name: name, qty: qty, descriptions: descriptions}}
    end
  end

  def parse(invalid_format) do
    Logger.warning("Invalid format: #{inspect(invalid_format)}")
    :error
  end
end
