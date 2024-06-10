defmodule Needlist.Repo.User do
  use Ecto.Schema

  alias Ecto.Changeset
  alias Needlist.Repo.Want

  @required_fields [:id, :username]
  @optional_fields []
  @fields @required_fields ++ @optional_fields

  @primary_key false
  schema "users" do
    field :id, :id, primary_key: true
    field :username, :string
    many_to_many :wants, Want, join_through: "user_wantlist"
  end

  @type t() :: %__MODULE__{}

  @spec changeset(t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(t() | Changeset.t(t())) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
  end
end
