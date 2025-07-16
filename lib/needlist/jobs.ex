defmodule Needlist.Jobs do
  @moduledoc """
  Context module for managing jobs. Dispatching is relegated to `Needlist.Oban.Dispatcher`.
  """

  alias Needlist.Repo
  alias Needlist.Repo.Job, as: CoreJob
  alias Oban.Job

  @spec last_wantlist_update_for_user(username :: String.t(), successful? :: boolean()) :: Job.t() | nil
  def last_wantlist_update_for_user(username, successful?) do
    job_state =
      if successful? do
        "completed"
      else
        nil
      end

    CoreJob.last_in_queue("wantlist", job_state)
    |> CoreJob.by_username_arg(username)
    |> Repo.one()
  end
end
