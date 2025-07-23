defmodule Needlist.Jobs do
  @moduledoc """
  Context module for managing jobs. Dispatching is relegated to `Needlist.Oban.Dispatcher`.
  """

  alias Needlist.Repo
  alias Needlist.Repo.Job, as: CoreJob
  alias Oban.Job

  @spec last_wantlist_update_for_user(username :: String.t(), successful? :: boolean()) :: Job.t() | nil
  def last_wantlist_update_for_user(username, successful?) do
    state_filter =
      if successful? do
        "completed"
      else
        nil
      end

    CoreJob.base_query()
    |> CoreJob.by_queue("wantlist")
    |> CoreJob.by_state(state_filter)
    |> CoreJob.by_username_arg(username)
    |> then(fn query ->
      if successful? do
        CoreJob.ordered_by_completed_at(query)
      else
        CoreJob.ordered_by_inserted_at(query)
      end
    end)
    |> Ecto.Query.first()
    |> Repo.one()
  end
end
