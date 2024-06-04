defmodule Nullables.Result do
  @moduledoc """
  Operations over types that represent a success value, or an error value
  """

  @type result(t, e) :: {:ok, t} | {:error, e}
  @type result(t) :: result(t, any())
  @type result() :: result(any(), any())

  @doc """
  Create a result with a value of the success variant
  """
  @spec ok(t) :: result(t) when t: var
  def ok(value), do: {:ok, value}

  @doc """
  Create a result with a value of the error variant
  """
  @spec error(e) :: result(any(), e) when e: var
  def error(error), do: {:error, error}

  @doc """
  Map the success variant of a result, leaving the error as-is
  """
  @spec map(result :: result(t, e), f :: (t -> u)) :: result(u, e) when t: var, u: var, e: var
  def map({:ok, value}, f), do: {:ok, f.(value)}
  def map({:error, _} = error, _f), do: error

  @doc """
  Map the error variant of the result, leaving the success as-is
  """
  @spec map_error(result :: result(t, e), f :: (e -> u)) :: result(t, u) when t: var, e: var, u: var
  def map_error({:ok, _value} = success, _f), do: success
  def map_error({:error, error}, f), do: {:error, f.(error)}
end
