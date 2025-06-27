defmodule Needlist.Users do
  @moduledoc """
  Users context.
  """

  alias Needlist.Discogs.Oauth
  alias Nullables.Result
  alias Needlist.Repo.User
  alias Needlist.Repo

  @spec all :: [User.t()]
  def all do
    User
    |> User.with_wantlist()
    |> Repo.all()
  end

  @spec get_by_username(String.t(), keyword()) :: Result.result(User.t())
  @spec get_by_username(String.t()) :: Result.result(User.t())
  def get_by_username(username, opts \\ []) do
    preload_wantlist? = Keyword.get(opts, :preload_wantlist, false)

    User
    |> User.by_username(username)
    |> User.maybe_with_wantlist(preload_wantlist?)
    |> Repo.one()
    |> Nullables.nullable_to_result(:not_found)
  end

  @spec get_by_id(id :: integer()) :: Result.result(User.t())
  def get_by_id(id) do
    User
    |> User.by_id(id)
    |> Repo.one()
    |> Nullables.nullable_to_result(:not_found)
  end

  @spec upsert_user_with_oauth_tokens(
          id :: integer(),
          username :: String.t(),
          token_pair :: Oauth.token_pair()
        ) :: Result.result(User.t())
  def upsert_user_with_oauth_tokens(id, username, {token, token_secret}) do
    params = %{id: id, username: username, oauth: %{token: token, token_secret: token_secret}}

    id
    |> get_by_id()
    |> Result.unwrap(%User{})
    |> User.changeset(params)
    |> Repo.insert_or_update()
  end

  @spec last_wantlist_update(username :: String.t()) :: DateTime.t() | nil
  def last_wantlist_update(username) do
    Needlist.Jobs.last_wantlist_completed_for_user(username)
    |> case do
      %Oban.Job{completed_at: completed_at} -> completed_at
      nil -> nil
    end
  end
end
