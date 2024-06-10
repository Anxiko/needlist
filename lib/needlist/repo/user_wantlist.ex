defmodule Needlist.Repo.UserWantlist do
  use Ecto.Schema

  alias Needlist.Repo.Want
  alias Needlist.Repo.User

  @primary_key false
  schema "user_wantlist" do
    belongs_to :user, User, primary_key: true
    belongs_to :wantlist, Want, primary_key: true
  end
end
