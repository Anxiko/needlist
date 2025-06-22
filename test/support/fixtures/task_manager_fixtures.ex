defmodule Needlist.TaskManagerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Needlist.TaskManager` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{
        args: %{},
        finished_at: ~U[2025-06-21 21:19:00Z],
        status: "some status",
        type: "some type"
      })
      |> Needlist.TaskManager.create_task()

    task
  end
end
