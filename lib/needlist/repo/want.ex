defmodule Needlist.Repo.Want do
  @moduledoc """
  Entry in a user's wantlist.
  """

  use Ecto.Schema

  import Ecto.Query

  alias Ecto.Changeset
  alias EctoExtra
  alias Needlist.Repo.Want.BasicInformation
  alias Needlist.Repo.User
  alias Needlist.Repo.Want.Artist
  alias Needlist.Repo.Want.Label

  @required_fields [:id, :date_added]
  @optional_fields []
  @embedded_fields [:basic_information]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  schema "wants" do
    field :id, :id, primary_key: true
    field :display_artists, :string
    field :display_labels, :string
    field :date_added, :utc_datetime
    embeds_one :basic_information, BasicInformation, on_replace: :update
    many_to_many :users, User, join_through: "user_wantlist"
  end

  use EctoExtra.SchemaType, schema: __MODULE__

  @type t() :: %__MODULE__{
          id: integer() | nil,
          display_artists: String.t() | nil,
          display_labels: String.t() | nil,
          date_added: DateTime.t() | nil,
          basic_information: BasicInformation.t() | nil
        }

  @type sort_order() :: :asc | :desc
  @type sort_key() :: :artist | :title | :label | :added

  @spec changeset(t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(map()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
    |> EctoExtra.cast_many_embeds(@embedded_fields)
    |> compute_sorting_fields()
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

  @spec in_user_needlist_by_username(Ecto.Query.t() | __MODULE__, String.t()) :: Ecto.Query.t()
  @spec in_user_needlist_by_username(String.t()) :: Ecto.Query.t()
  def in_user_needlist_by_username(query \\ __MODULE__, username) do
    query
    |> join(:inner, [w], u in assoc(w, :users))
    |> where([_w, u], u.username == ^username)
    |> select([w, _u], w)
  end

  @spec sort_by_artists(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  @spec sort_by_artists(sort_order()) :: Ecto.Query.t()
  def sort_by_artists(query \\ __MODULE__, order) do
    query
    |> Ecto.Query.order_by([{^order, :display_artists}])
  end

  @spec sort_by_title(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  @spec sort_by_title(sort_order()) :: Ecto.Query.t()
  def sort_by_title(query \\ __MODULE__, order) do
    query
    |> Ecto.Query.order_by([w], [{^order, fragment("?->>?", w.basic_information, "title")}])
  end

  @spec sort_by_labels(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  @spec sort_by_labels(sort_order()) :: Ecto.Query.t()
  def sort_by_labels(query \\ __MODULE__, order) do
    query
    |> Ecto.Query.order_by([{^order, :display_labels}])
  end

  @spec sort_by_date_added(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  @spec sort_by_date_added(sort_order()) :: Ecto.Query.t()
  def sort_by_date_added(query \\ __MODULE__, order) do
    query
    |> Ecto.Query.order_by([{^order, :date_added}])
  end

  @spec sort_by(Ecto.Query.t() | __MODULE__, sort_key(), sort_order()) :: Ecto.Query.t()
  @spec sort_by(sort_key(), sort_order()) :: Ecto.Query.t()
  def sort_by(query \\ __MODULE__, sort_key, sort_order)
  def sort_by(query, :artist, sort_order), do: sort_by_artists(query, sort_order)
  def sort_by(query, :title, sort_order), do: sort_by_labels(query, sort_order)
  def sort_by(query, :label, sort_order), do: sort_by_labels(query, sort_order)
  def sort_by(query, :added, sort_order), do: sort_by_date_added(query, sort_order)

  defp compute_sorting_fields(%Ecto.Changeset{valid?: true} = changeset) do
    changeset
    |> Changeset.fetch_field(:basic_information)
    |> case do
      {_source, %BasicInformation{artists: artists, labels: labels}} ->
        changeset
        |> Changeset.put_change(:display_artists, Artist.display_artists(artists))
        |> Changeset.put_change(:display_labels, Label.display_labels(labels))

      _ ->
        changeset
    end
  end

  @spec paginated(Ecto.Query.t() | __MODULE__, pos_integer(), pos_integer()) :: Ecto.Query.t()
  @spec paginated(pos_integer(), pos_integer()) :: Ecto.Query.t()
  def paginated(query \\ __MODULE__, page, per_page) do
    offset = per_page * (page - 1)

    query
    |> limit(^per_page)
    |> offset(^offset)
  end
end
