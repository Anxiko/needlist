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

  @doc """
  Map a result's success value if present, using a function that produces another result
  """
  @spec flat_map(result(t, e), (t -> result(u, e))) :: result(u, e) when t: var, u: var, e: var
  def flat_map({:error, _} = error, _f), do: error

  def flat_map({:ok, value}, f) do
    f.(value)
  end

  @doc """
  Returns whether a result is the success variant
  """
  @spec ok?(result()) :: boolean()
  def ok?({:ok, _}), do: true
  def ok?({:error, _}), do: false

  @doc """
  Extract the value from a result.
  If the result is in error, it will raise an `ArgumentError`.
  """
  @spec unwrap!(result(t)) :: t when t: var
  def unwrap!({:ok, value}), do: value

  def unwrap!(:error) do
    raise ArgumentError, "Attempted to unwrap a result in error"
  end

  @doc """
  Get the value from the result if present, otherwise get a default value.
  """
  @spec unwrap(result(t), d) :: t | d when t: var, d: var
  def unwrap(fallible, default \\ nil)
  def unwrap({:ok, value}, _default), do: value
  def unwrap({:error, _}, default), do: default

  @doc """
  Collapse an enumerable of results, into a result of an enumerable.
  If any of the elements are in error, that error becomes the result.
  Otherwise, the success result is the list of unwrapped values.
  """
  @spec try_reduce(Enumerable.t(result(t, e))) :: result([t], e) when t: var, e: var
  def try_reduce(results) do
    results
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, value}, {:ok, values} ->
        {:cont, {:ok, [value | values]}}

      {:error, error}, _acc ->
        {:halt, {:error, error}}
    end)
    |> map(&Enum.reverse/1)
  end

  @doc """
  Transform the error variant of a result, wrapping the error details in a tuple with the tag.
  The success variant is left untouched.
  Useful in with chains, to identify which step caused a failure.
  """
  @spec tag_error(result :: result(t, e), tag :: tag) :: result(t, {tag, e}) when t: var, e: var, tag: var
  def tag_error({:ok, _} = result, _tag), do: result
  def tag_error({:error, error}, tag), do: {:error, {tag, error}}
end
