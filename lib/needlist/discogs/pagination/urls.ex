defmodule Needlist.Discogs.Pagination.Urls do
  @moduledoc """
  Next and last URLs included in a paginated Discogs API response
  """

  @keys [:last, :next]
  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          last: String.t(),
          next: String.t()
        }

  @spec parse(map()) :: {:ok, t()} | :error
  def parse(%{"last" => last, "next" => next}) when is_binary(last) and is_binary(next) do
    {:ok, %__MODULE__{last: last, next: next}}
  end

  def parse(_), do: :error
end
