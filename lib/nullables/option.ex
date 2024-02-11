defmodule Nullables.Option do
  @moduledoc """
  Operations over nullable types
  """

  @type option(t) :: {:ok, t} | :error
  @type option() :: option(any())

  @doc """
  Converts a nullable value into an option
  """
  @spec required(nullable :: t | nil) :: option(t) when t: var
  def required(nil), do: :error
  def required(value), do: {:ok, value}

  @doc """
  If the option contains a value, call the function with accumulator and the value as arguments.
  Otherwise, return the accumulator as-is.
  """
  @spec apply_if(acc, option(t), (t, acc -> acc)) :: acc when t: var, acc: var
  def apply_if(acc, :error, _f), do: acc
  def apply_if(acc, {:ok, value}, f), do: f.(acc, value)

  @doc """
  Map an option's inner value if present
  """
  @spec map(option(t), (t -> u)) :: option(u) when t: var, u: var
  def map(:error, _f), do: :error
  def map({:ok, value}, f), do: {:ok, f.(value)}
end
