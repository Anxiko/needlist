defmodule Nullables do
  @moduledoc """
  Helpers and conversions between the different nullable types.
  """
  alias Nullables.Result
  alias Nullables.Fallible

  @type null(e) :: {:error, e} | :error | nil

  @type nullable(t, e) :: {:ok, t} | null(e)
  @type nullable(t) :: nullable(t, any())
  @type nullable() :: nullable(any())

  @spec fallible_to_result(Fallible.fallible(t), e) :: Result.result(t, e) when t: var, e: var
  def fallible_to_result({:ok, _value} = success, _fail_with), do: success
  def fallible_to_result(:error, fail_with), do: {:error, fail_with}

  @spec nullable_to_fallible(t | nil) :: Fallible.fallible(t) when t: var
  def nullable_to_fallible(nil), do: :error
  def nullable_to_fallible(value), do: {:ok, value}

  @spec nullable_to_result(t | nil, e) :: Result.result(t, e) when t: var, e: var
  def nullable_to_result(nil, fail_with), do: {:error, fail_with}
  def nullable_to_result(value, _fail_with), do: {:ok, value}

  @doc """
  Normalizes a null value (`nil`, fallible error variant, or result error variant), into the error variant of a result.
  If the null value is tagged with an atom on a pair, the error details will be paired with the tag.
  If the value is not a null value, it will be wrapped within an error.
  Meant to be used in the `else` clause of a `with`, ensuring a consistent shape of all possible error return values.
  """
  @spec normalize(null :: null(e) | {tag, null(e)} | e) :: {:error, e} when e: var, tag: atom()
  def normalize({:error, _details} = error), do: error
  def normalize(:error), do: {:error, :unknown}
  def normalize(nil), do: {:error, :missing}
  def normalize({tag, {:error, details}}) when is_atom(tag), do: {:error, {tag, details}}
  def normalize({tag, :error}) when is_atom(tag), do: {:error, tag}
  def normalize({tag, nil}) when is_atom(tag), do: {:error, tag}
  def normalize(error), do: {:error, error}
end
