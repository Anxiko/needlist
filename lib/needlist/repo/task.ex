defmodule Needlist.Repo.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_statuses [:created, :running, :completed, :failed]
  @final_statuses [:completed, :failed]

  schema "tasks" do
    field :args, :map
    field :status, Ecto.Enum, values: @valid_statuses
    field :type, :string
    field :finished_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:type, :status, :args, :finished_at])
    |> validate_required([:type, :status, :args])
    |> validate_timestamp_on_finish()
  end

  defguardp final_status?(state) when state in @final_statuses

  defp validate_timestamp_on_finish(changeset) do
    case {get_field(changeset, :status), get_field(changeset, :finished_at)} do
      {final_status, nil} when final_status?(final_status) ->
        add_error(changeset, :finished_at, "must be set when status is final")

      {not_final, finished_at} when not final_status?(not_final) and finished_at != nil ->
        add_error(changeset, :finished_at, "can't be set when status is not finished")

      _ ->
        changeset
    end
  end
end
