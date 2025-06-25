defmodule Needlist.Oban.Dispatcher do
  @moduledoc """
  Creates and enqueues Oban jobs.
  """

  alias Needlist.Oban.Worker.Wantlist, as: WantlistWorker

  @spec dispatch_wantlist(String.t()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def dispatch_wantlist(username) do
    %{username: username}
    |> WantlistWorker.new()
    |> Oban.insert()
  end
end
