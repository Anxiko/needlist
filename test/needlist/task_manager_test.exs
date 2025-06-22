defmodule Needlist.TaskManagerTest do
  use Needlist.DataCase

  alias Needlist.TaskManager

  describe "tasks" do
    alias Needlist.Repo.Task

    import Needlist.TaskManagerFixtures

    @invalid_attrs %{args: nil, status: nil, type: nil, finished_at: nil}

    test "list_tasks/0 returns all tasks" do
      task = task_fixture()
      assert TaskManager.list_tasks() == [task]
    end

    test "get_task!/1 returns the task with given id" do
      task = task_fixture()
      assert TaskManager.get_task!(task.id) == task
    end

    test "create_task/1 with valid data creates a task" do
      valid_attrs = %{args: %{}, status: "some status", type: "some type", finished_at: ~U[2025-06-21 21:19:00Z]}

      assert {:ok, %Task{} = task} = TaskManager.create_task(valid_attrs)
      assert task.args == %{}
      assert task.status == "some status"
      assert task.type == "some type"
      assert task.finished_at == ~U[2025-06-21 21:19:00Z]
    end

    test "create_task/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = TaskManager.create_task(@invalid_attrs)
    end

    test "update_task/2 with valid data updates the task" do
      task = task_fixture()
      update_attrs = %{args: %{}, status: "some updated status", type: "some updated type", finished_at: ~U[2025-06-22 21:19:00Z]}

      assert {:ok, %Task{} = task} = TaskManager.update_task(task, update_attrs)
      assert task.args == %{}
      assert task.status == "some updated status"
      assert task.type == "some updated type"
      assert task.finished_at == ~U[2025-06-22 21:19:00Z]
    end

    test "update_task/2 with invalid data returns error changeset" do
      task = task_fixture()
      assert {:error, %Ecto.Changeset{}} = TaskManager.update_task(task, @invalid_attrs)
      assert task == TaskManager.get_task!(task.id)
    end

    test "delete_task/1 deletes the task" do
      task = task_fixture()
      assert {:ok, %Task{}} = TaskManager.delete_task(task)
      assert_raise Ecto.NoResultsError, fn -> TaskManager.get_task!(task.id) end
    end

    test "change_task/1 returns a task changeset" do
      task = task_fixture()
      assert %Ecto.Changeset{} = TaskManager.change_task(task)
    end
  end
end
