defmodule Needlist.Repo.Task.Status do
  @moduledoc """
  Status of a managed task.
  """

  @values [:created, :running, :completed, :failed]
  @final_values [:completed, :failed]

  use AtomEnum, values: @values

  @spec final_values() :: [t()]
  def final_values, do: @final_values

  defguard status_final?(status) when status in @final_values
end
