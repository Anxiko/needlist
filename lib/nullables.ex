defmodule Nullables do
  @moduledoc """
  Helpers and conversions between the different nullable types.
  """
  alias Nullables.Result
  alias Nullables.Fallible

  @spec fallible_to_result(Fallible.fallible(t), e) :: Result.result(t, e) when t: var, e: var
  def fallible_to_result({:ok, _value} = success, _fail_with), do: success
  def fallible_to_result(:error, fail_with), do: {:error, fail_with}
end
