defmodule Needlist.Repo.Wantlist do
  @moduledoc """
  N:N relationship table between users and releases in their wantlist.
  """

  use Ecto.Schema

  alias Needlist.Repo.Release
  alias Needlist.Repo.User

  @primary_key false
  schema "user_wantlist" do
    belongs_to :user, User, primary_key: true
    belongs_to :release, Release, primary_key: true
    field :notes, :string
    field :date_added, :utc_datetime

    timestamps()
  end
end
