defmodule Needlist.Discogs.Guards do
  @moduledoc """
  Guards to be used on API response parsing and validation
  """

  defguard is_pos_integer(x) when is_integer(x) and x > 0
  defguard is_non_neg_integer(x) when is_integer(x) and x >= 0
end
