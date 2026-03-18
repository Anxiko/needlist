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
  def job_finished(worker, %Job{} = job) do
    job_update(worker, job, :finished)
  end

  @spec job_failed(worker(), Oban.Job.t()) :: :ok | {:error, any()}
  def job_failed(worker, %Job{} = job) do
    job_update(worker, job, :failed)
  end

  defp job_update(worker, %Job{args: args} = job, status) do
    PubSub.broadcast(@name, job_channel(worker, args), {:job_update, %{job: job, worker: worker, status: status}})
  end

  @spec subscribe_wantlist_updates(username :: String.t()) :: :ok | {:error, {:already_registered, pid()}}
  def subscribe_wantlist_updates(username) do
    PubSub.subscribe(@name, "job:wantlist:#{username}")
  end

  @spec job_channel(worker(), args :: map()) :: String.t()
  defp job_channel(WantlistWorker, %{"username" => username}), do: "job:wantlist:#{username}"
  defp job_channel(ListingsWorker, %{"release_id" => release_id}), do: "job:listings:#{release_id}"
  defp job_channel(BatchjobWorker, %{"type" => type}), do: "job:batchjob:#{type}"
end
