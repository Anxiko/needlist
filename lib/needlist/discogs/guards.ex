defmodule Needlist.Discogs.Guards do
  @moduledoc """
  Guards to be used on API response parsing and validation
  """

  defguard is_pos_integer(x) when is_integer(x) and x > 0
  defguard is_non_neg_integer(x) when is_integer(x) and x >= 0

  defguard is_maybe_string(maybe_string) when is_nil(maybe_string) or is_binary(maybe_string)

  defguard is_integer_or_raw(integer_or_raw)
           when is_integer(integer_or_raw) or is_binary(integer_or_raw)
end
