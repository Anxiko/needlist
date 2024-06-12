defmodule Needlist.Repo.Want do
  use Ecto.Schema

  import Ecto.Query

  alias Ecto.Changeset
  alias EctoExtra
  alias Needlist.Repo.Want.BasicInformation
  alias Needlist.Repo.User

  @required_fields [:id]
  @optional_fields []
  @embedded_fields [:basic_information]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  schema "wants" do
    field :id, :id, primary_key: true
    embeds_one :basic_information, BasicInformation, on_replace: :update
    many_to_many :users, User, join_through: "user_wantlist"
  end

  use EctoExtra.SchemaType, schema: __MODULE__

  @type t() :: %__MODULE__{
          id: integer() | nil,
          basic_information: BasicInformation.t() | nil
        }

  @spec changeset(t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(map()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
    |> EctoExtra.cast_many_embeds(@embedded_fields)
  end

  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @spec in_user_needlist(Ecto.Query.t() | __MODULE__, integer()) :: Ecto.Query.t()
  @spec in_user_needlist(integer()) :: Ecto.Query.t()
  def in_user_needlist(query \\ __MODULE__, user_id) do
    query
    |> join(:inner, [w], u in assoc(w, :users))
    |> where([_w, u], u.id == ^user_id)
    |> select([w, _u], w)
  end
end
