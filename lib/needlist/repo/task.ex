defmodule Needlist.Repo.Task do
  @moduledoc """
  A managed task, usually for scraping data from Discogs.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Needlist.Repo.Task.Status, only: [status_final?: 1]

  alias Needlist.Repo.Task.Status

  @type t() :: %__MODULE__{
          id: integer(),
          args: map(),
          status: Status.t(),
          type: String.t(),
          finished_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "tasks" do
    field :args, :map
    field :status, Ecto.Enum, values: Status.values()
    field :type, :string
    field :finished_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(task :: t() | %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t(t())
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:type, :status, :args, :finished_at])
    |> validate_required([:type, :status, :args])
    |> validate_timestamp_on_finish()
  end

  @spec validate_timestamp_on_finish(Ecto.Changeset.t(t())) :: Ecto.Changeset.t(t())
  defp validate_timestamp_on_finish(changeset) do
    case {get_field(changeset, :status), get_field(changeset, :finished_at)} do
      {final_status, nil} when status_final?(final_status) ->
        add_error(changeset, :finished_at, "must be set when status is final")

      {not_final, finished_at} when not status_final?(not_final) and finished_at != nil ->
        add_error(changeset, :finished_at, "can't be set when status is not finished")

      _ ->
        changeset
    end
  end
end
