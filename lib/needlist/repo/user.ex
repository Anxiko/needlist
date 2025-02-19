defmodule Needlist.Repo.User do
  @moduledoc """
  Discogs' user.
  """

  use Ecto.Schema

  import Ecto.Query

  alias Ecto.Changeset
  alias EctoExtra.DumpableSchema
  alias Ecto.Association.NotLoaded
  alias Needlist.Repo.Want
  alias Needlist.Repo.User.Oauth

  @required_fields [:id, :username]
  @optional_fields []
  @embedded_fields [
    {:oauth, [:required]}
  ]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  schema "users" do
    field :id, :id, primary_key: true
    field :username, :string
    embeds_one :oauth, Oauth, on_replace: :update
    many_to_many :wants, Want, join_through: "user_wantlist"
  end

  @type t() :: %__MODULE__{
          id: integer(),
          username: String.t(),
          oauth: Oauth.t() | nil,
          wants: [Want.t()] | NotLoaded.t()
        }

  use EctoExtra.SchemaType, schema: __MODULE__

  @spec new() :: %__MODULE__{}
  def new(), do: %__MODULE__{}

  @spec changeset(%__MODULE__{} | t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(%__MODULE__{} | t() | Changeset.t(t())) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> EctoExtra.cast_many_embeds(@embedded_fields)
    |> Changeset.validate_required(@required_fields)
  end

  @spec by_id(Ecto.Query.t() | __MODULE__, integer()) :: Ecto.Query.t()
  @spec by_id(integer()) :: Ecto.Query.t()
  def by_id(query \\ __MODULE__, id) do
    where(query, id: ^id)
  end

  @spec by_username(Ecto.Query.t() | __MODULE__, String.t()) :: Ecto.Query.t()
  @spec by_username(String.t()) :: Ecto.Query.t()
  def by_username(query \\ __MODULE__, username) do
    where(query, username: ^username)
  end

  @spec with_wantlist(Ecto.Query.t() | __MODULE__) :: Ecto.Query.t()
  @spec with_wantlist() :: Ecto.Query.t()
  def with_wantlist(query \\ __MODULE__) do
    preload(query, :wants)
  end

  @spec maybe_with_wantlist(Ecto.Query.t() | __MODULE__, boolean()) :: Ecto.Query.t()
  @spec maybe_with_wantlist(boolean()) :: Ecto.Query.t()
  def maybe_with_wantlist(query \\ __MODULE__, preload_wantlist?)
  def maybe_with_wantlist(query, true), do: with_wantlist(query)
  def maybe_with_wantlist(query, false), do: query

  defimpl DumpableSchema do
    @spec dump(@for.t()) :: map()
    def dump(user) do
      user
      |> Map.from_struct()
      |> Map.take([:id, :username, :ouath])
      |> DumpableSchema.Embeds.dump_embed_fields([:oauth])
    end
  end
end
