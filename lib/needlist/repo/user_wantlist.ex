defmodule Needlist.Repo.UserWantlist do
  @moduledoc """
  N:N relationship table between users and wantlist entries.
  """

  use Ecto.Schema

  alias Needlist.Repo.Want
  alias Needlist.Repo.User

  @primary_key false
  schema "user_wantlist" do
    belongs_to :user, User, primary_key: true
    belongs_to :wantlist, Want, primary_key: true
  end
end
