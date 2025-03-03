defmodule Needlist.Repo.Wantlist do
  @moduledoc """
  N:N relationship table between users and releases in their wantlist.
  """

  use Ecto.Schema

  import Ecto.Query
  import EctoExtra, only: [nullable_amount_to_money: 2]

  alias Ecto.Association.NotLoaded
  alias Needlist.Types.QueryOptions.SortOrder
  alias Needlist.Types.QueryOptions.SortKey
  alias Needlist.Repo.Want
  alias Ecto.Changeset
  alias Needlist.Repo.Release
  alias Needlist.Repo.User

  @required [:user_id, :release_id, :date_added]
  @optional [:notes, :rating]

  @sorted_by_release Release.fields_sorted_by_release()

  @type t() :: %__MODULE__{
          user_id: integer(),
          release_id: integer(),
          date_added: DateTime.t(),
          notes: String.t() | nil,
          rating: non_neg_integer() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t(),
          user: User.t() | NotLoaded.t(),
          release: Release.t() | NotLoaded.t()
        }

  @primary_key false
  schema "wantlist" do
    belongs_to :user, User, primary_key: true
    belongs_to :release, Release, primary_key: true
    field :notes, :string
    field :rating, :integer
    field :date_added, :utc_datetime

    timestamps()
  end

  @spec changeset(wantlist :: %__MODULE__{} | t() | Changeset.t(t()), data :: map()) :: Changeset.t(t())
  @spec changeset(data :: map()) :: Changeset.t(t())
  def changeset(wantlist \\ %__MODULE__{}, data) do
    wantlist
    |> Changeset.cast(data, @required ++ @optional)
    |> Changeset.validate_required(@required)
    |> EctoExtra.validate_number(:rating, [:non_neg])
  end

  @spec from_scrapped_want(want :: Want.t(), release_id :: non_neg_integer()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def from_scrapped_want(%Want{id: release_id, notes: notes, rating: rating, date_added: date_added}, user_id) do
    %{user_id: user_id, release_id: release_id, date_added: date_added, notes: notes, rating: rating}
    |> changeset()
    |> Changeset.apply_action(:cast)
  end

  @spec sort_by(query :: Ecto.Query.t(), key :: SortKey.t(), order :: SortOrder.t()) :: Ecto.Query.t()
  def sort_by(query, key, order) when key in @sorted_by_release do
    Release.sort_by(query, key, order)
  end

  def sort_by(query, :rating, order) do
    order_by(query, [wantlist: w], {^SortOrder.nulls_last(order), w.rating})
  end

  def sort_by(query, :added, order) do
    order_by(query, [wantlist: w], {^SortOrder.nulls_last(order), w.date_added})
  end

  def sort_by(query, :notes, order) do
    order_by(query, [wantlist: w], {^SortOrder.nulls_last(order), w.notes})
  end

  @spec named_binding(query :: Ecto.Query.t() | __MODULE__) :: Ecto.Query.t()
  @spec named_binding() :: Ecto.Query.t()
  def named_binding(query \\ __MODULE__) do
    from(query, as: :wantlist)
  end

  @spec with_user(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def with_user(query) do
    query
    |> join(:inner, [wantlist: w], u in assoc(w, :user), as: :users)
    |> preload([users: u], user: u)
  end

  @spec with_release(query :: Ecto.Query.t(), currency :: String.t()) :: Ecto.Query.t()
  def with_release(query, currency) do
    query
    |> join(:inner, [wantlist: w], r in assoc(w, :release), as: :releases)
    |> Release.with_price_stats(currency)
    |> select_merge([wantlist: w, releases: r, listings: l], %{
      w
      | release: %{
          r
          | min_price: nullable_amount_to_money(l.min_price, ^currency),
            avg_price: nullable_amount_to_money(l.avg_price, ^currency),
            max_price: nullable_amount_to_money(l.max_price, ^currency)
        }
    })
  end

  @spec by_username(query :: Ecto.Query.t(), username :: String.t()) :: Ecto.Query.t()
  def by_username(query, username) do
    where(query, [users: u], u.username == ^username)
  end

  @spec by_release_id(query :: Ecto.Query.t(), release_id :: integer()) :: Ecto.Query.t()
  def by_release_id(query, release_id) do
    where(query, [wantlist: w], w.release_id == ^release_id)
  end

  @spec paginated(query :: Ecto.Query.t(), page :: pos_integer(), per_page :: pos_integer()) :: Ecto.Query.t()
  def paginated(query, page, per_page) do
    offset = per_page * (page - 1)

    query
    |> limit(^per_page)
    |> offset(^offset)
  end
end
