defmodule Nullables.Fallible do
  @moduledoc """
  Operations over types that might be a value or an unspecified error
  """

  @type fallible(t) :: {:ok, t} | :error
  @type fallible() :: fallible(any())

  @doc """
  Converts a nullable value into an fallible
  """
  @spec from_nullable(nullable :: t | nil) :: fallible(t) when t: var
  def from_nullable(nil), do: :error
  def from_nullable(value), do: {:ok, value}

  @doc """
  Create a fallible with a value
  """
  @spec ok(t) :: fallible(t) when t: var
  def ok(value), do: {:ok, value}

  @doc """
  Returns whether a fallible is OK
  """
  @spec ok?(fallible()) :: boolean()
  def ok?({:ok, _}), do: true
  def ok?(:error), do: false

  @doc """
  Extract the value from a fallible.
  If the fallible had no value, it will raise an `ArgumentError`.
  """
  @spec unwrap!(fallible(t)) :: t when t: var
  def unwrap!(:ok, value), do: value

  def unwrap!(:error) do
    raise ArgumentError, "Attempted to unwrap a fallible in error"
  end

  @doc """
  If the fallible contains a value, call the function with accumulator and the value as arguments.
  Otherwise, return the accumulator as-is.
  """
  @spec apply_if(acc :: acc, fallible :: fallible(t), f :: (acc, t -> acc)) :: acc when t: var, acc: var
  def apply_if(acc, :error, _f), do: acc
  def apply_if(acc, {:ok, value}, f), do: f.(acc, value)

  @doc """
  Map a fallible's inner value if present
  """
  @spec map(fallible(t), (t -> u)) :: fallible(u) when t: var, u: var
  def map(:error, _f), do: :error
  def map({:ok, value}, f), do: {:ok, f.(value)}

  @doc """
  Map a fallible's inner value if present, using a function that also produces a fallible
  """
  @spec flat_map(fallible(t), (t -> fallible(u))) :: fallible(u) when t: var, u: var
  def flat_map(:error, _f), do: :error

  def flat_map({:ok, value}, f) do
    f.(value)
  end

  @doc """
  Chain of flat_map calls, over an starting fallible
  """
  @spec flat_map_many(fallible(), [(fallible() -> fallible())]) :: fallible()
  def flat_map_many(fallible, functions) do
    Enum.reduce(functions, fallible, fn f, acc -> flat_map(acc, f) end)
  end
end
