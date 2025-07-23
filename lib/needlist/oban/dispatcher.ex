defmodule Needlist.Oban.Dispatcher do
  @moduledoc """
  Creates and enqueues Oban jobs.
  """

  alias Needlist.Oban.Worker.Wantlist, as: WantlistWorker
  alias Needlist.Oban.Worker.Listings, as: ListingsWorker
  alias Needlist.Oban.Worker.Batchjob, as: BatchjobWorker
  alias Needlist.Repo

  @spec dispatch_wantlist(String.t()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def dispatch_wantlist(username) do
    %{username: username}
    |> WantlistWorker.new()
    |> Oban.insert()
    |> refresh_job_in_result()
  end

  @spec dispatch_listings(integer()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def dispatch_listings(release_id) do
    %{release_id: release_id}
    |> ListingsWorker.new()
    |> Oban.insert()
    |> refresh_job_in_result()
  end

  @spec dispatch_wantlist_batch :: {:ok, Oban.Job.t()} | {:error, any()}
  def dispatch_wantlist_batch do
    %{type: :wantlist}
    |> BatchjobWorker.new()
    |> Oban.insert()
    |> refresh_job_in_result()
  end

  @spec dispatch_listings_batch :: {:ok, Oban.Job.t()} | {:error, any()}
  def dispatch_listings_batch do
    %{type: :listings}
    |> BatchjobWorker.new()
    |> Oban.insert()
    |> refresh_job_in_result()
  end

  # The result of a successful job insertion seems to be missing some timestamps, since these are calculated by Postgres and not returned.
  # By refetching the job from the database, we ensure that we have all the necessary fields populated.
  defp refresh_job_in_result({:ok, %Oban.Job{id: id}}) do
    {:ok, Repo.get!(Oban.Job, id)}
  end

  defp refresh_job_in_result(error), do: error
end
