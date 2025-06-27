defmodule Needlist.Jobs do
  @moduledoc """
  Context module for managing jobs. Dispatching is relegated to `Needlist.Oban.Dispatcher`.
  """

  alias Needlist.Repo
  alias Needlist.Repo.Job, as: CoreJob
  alias Oban.Job

  @spec last_wantlist_completed_for_user(username:: String.t()) :: Job.t() | nil
  def last_wantlist_completed_for_user(username) do
    CoreJob.last_completed_for_queue("wantlist")
    |> CoreJob.by_username_arg(username)
    |> Repo.one()
  end
end
