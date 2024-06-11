defmodule Nullables do
  @moduledoc """
  Helpers and conversions between the different nullable types.
  """
  alias Nullables.Result
  alias Nullables.Fallible

  @spec fallible_to_result(Fallible.fallible(t), e) :: Result.result(t, e) when t: var, e: var
  def fallible_to_result({:ok, _value} = success, _fail_with), do: success
  def fallible_to_result(:error, fail_with), do: {:error, fail_with}

  @spec nullable_to_fallible(t | nil) :: Fallible.fallible(t) when t: var
  def nullable_to_fallible(nil), do: :error
  def nullable_to_fallible(value), do: {:ok, value}

  @spec nullable_to_result(t | nil, e) :: Result.result(t, e) when t: var, e: var
  def nullable_to_result(nil, fail_with), do: {:error, fail_with}
  def nullable_to_result(value, _fail_with), do: {:ok, value}
end
