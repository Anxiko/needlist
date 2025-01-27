defmodule Needlist.Repo.Wantlist do
  @moduledoc """
  N:N relationship table between users and releases in their wantlist.
  """

  use Ecto.Schema

  alias Needlist.Repo.Want
  alias Ecto.Changeset
  alias Needlist.Repo.Release
  alias Needlist.Repo.User

  @required [:user_id, :release_id, :date_added]
  @optional [:notes]

  @type t() :: %__MODULE__{
          user_id: integer(),
          release_id: integer(),
          date_added: DateTime.t(),
          notes: String.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key false
  schema "wantlist" do
    belongs_to :user, User, primary_key: true
    belongs_to :release, Release, primary_key: true
    field :notes, :string
    field :date_added, :utc_datetime

    timestamps()
  end

  @spec changeset(wantlist :: %__MODULE__{} | t() | Changeset.t(t()), data :: map()) :: Changeset.t(t())
  @spec changeset(data :: map()) :: Changeset.t(t())
  def changeset(wantlist \\ %__MODULE__{}, data) do
    wantlist
    |> Changeset.cast(data, @required ++ @optional)
    |> Changeset.validate_required(@required)
  end

  @spec from_want(Want.t()) :: {:ok, [t()]} | {:error, Changeset.t(t())}
  def from_want(%Want{id: release_id, notes: notes, date_added: date_added, users: users}) do
    users
    |> Enum.map(fn %User{id: user_id} ->
      %{user_id: user_id, release_id: release_id, notes: notes, date_added: date_added}
      |> changeset()
      |> Changeset.apply_action(:cast)
    end)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, %__MODULE__{} = wantlist}, {:ok, acc} ->
        {:cont, {:ok, [wantlist | acc]}}

      {:error, changeset}, _acc ->
        {:halt, changeset}
    end)
  end
end
