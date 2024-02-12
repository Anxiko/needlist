defmodule Needlist.Parser do
  import Needlist.Guards, only: [is_pos_integer: 1]

  @spec parse_int(binary()) :: {:ok, integer()} | :error
  def parse_int(raw_int) when is_binary(raw_int) do
    case Integer.parse(raw_int) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  @spec validate_pos_integer(integer()) :: {:ok, pos_integer()} | :error
  def validate_pos_integer(int) when is_pos_integer(int), do: {:ok, int}
  def validate_pos_integer(int) when is_integer(int), do: :error
end
