defmodule Needlist.Users do
  @moduledoc """
  Users context.
  """

  alias Nullables.Result
  alias Needlist.Repo.User
  alias Needlist.Repo

  @spec get_by_username(String.t(), keyword()) :: Result.result(User.t())
  @spec get_by_username(String.t()) :: Result.result(User.t())
  def get_by_username(username, opts \\ []) do
    preload_wantlist? = Keyword.get(opts, :preload_wantlist, true)

    User
    |> User.by_username(username)
    |> User.maybe_with_wantlist(preload_wantlist?)
    |> Repo.one()
    |> Nullables.nullable_to_result(:not_found)
  end
end
