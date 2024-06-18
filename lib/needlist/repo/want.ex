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
    field :display_artists, :string
    embeds_one :basic_information, BasicInformation, on_replace: :update
    many_to_many :users, User, join_through: "user_wantlist"
  end

  use EctoExtra.SchemaType, schema: __MODULE__

  @type t() :: %__MODULE__{
          id: integer() | nil,
          display_artists: String.t() | nil,
          basic_information: BasicInformation.t() | nil
        }

  @spec changeset(t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(map()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
    |> EctoExtra.cast_many_embeds(@embedded_fields)
    |> compute_display_artists()
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

  defp compute_display_artists(%Ecto.Changeset{valid?: true} = changeset) do
    changeset
    |> Changeset.fetch_field(:basic_information)
    |> case do
      {_source, %BasicInformation{artists: artists}} when is_list(artists) ->
        changeset
        |> Changeset.put_change(:display_artists, Needlist.Repo.Want.Artist.display_artists(artists))

      _ ->
        changeset
    end
  end
end
