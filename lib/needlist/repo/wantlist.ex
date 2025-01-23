defmodule Needlist.Repo.Wantlist do
  @moduledoc """
  N:N relationship table between users and releases in their wantlist.
  """

  use Ecto.Schema

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
  schema "user_wantlist" do
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
end
