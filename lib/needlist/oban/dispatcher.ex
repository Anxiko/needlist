defmodule Needlist.Oban.Dispatcher do
  @moduledoc """
  Creates and enqueues Oban jobs.
  """

  alias Needlist.Oban.Worker.Wantlist, as: WantlistWorker
  alias Needlist.Oban.Worker.Listings, as: ListingsWorker
  alias Needlist.Oban.Worker.Batchjob, as: BatchjobWorker

  @spec dispatch_wantlist(String.t()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def dispatch_wantlist(username) do
    %{username: username}
    |> WantlistWorker.new()
    |> Oban.insert()
  end

  @spec dispatch_listings(integer()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def dispatch_listings(release_id) do
    %{release_id: release_id}
    |> ListingsWorker.new()
    |> Oban.insert()
  end

  @spec dispatch_wantlist_batch :: {:ok, Oban.Job.t()} | {:error, any()}
  def dispatch_wantlist_batch do
    %{type: :wantlist}
    |> BatchjobWorker.new()
    |> Oban.insert()
  end

  @spec dispatch_listings_batch :: {:ok, Oban.Job.t()} | {:error, any()}
  def dispatch_listings_batch do
    %{type: :listings}
    |> BatchjobWorker.new()
    |> Oban.insert()
  end
end
