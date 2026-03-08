defmodule Needlist.PubSub do
  @moduledoc """
  Wrapper around `Phoenix.PubSub` for Needlist operations.
  """

  alias Needlist.Oban.Worker.Listings, as: ListingsWorker
  alias Needlist.Oban.Worker.Wantlist, as: WantlistWorker
  alias Needlist.Oban.Worker.Batchjob, as: BatchjobWorker
  alias Phoenix.PubSub
  alias Oban.Job

  @name __MODULE__

  @type worker() :: BatchjobWorker | ListingsWorker | WantlistWorker

  @spec job_finished(worker(), Job.t()) :: :ok | {:error, any()}
  def job_finished(worker, %Job{args: args} = job) do
    PubSub.broadcast(@name, job_channel(worker, args), {:job_update, %{job: job, worker: worker, status: :finished}})
  end

  @spec subscribe_finished_wantlist(username :: String.t()) :: :ok | {:error, {:already_registered, pid()}}
  def subscribe_finished_wantlist(username) do
    PubSub.subscribe(@name, "job:wantlist:#{username}")
  end

  @spec job_channel(worker(), args :: map()) :: String.t()
  defp job_channel(WantlistWorker, %{"username" => username}), do: "job:wantlist:#{username}"
  defp job_channel(ListingsWorker, %{"release_id" => release_id}), do: "job:listings:#{release_id}"
  defp job_channel(BatchjobWorker, %{"type" => type}), do: "job:batchjob:#{type}"
end
