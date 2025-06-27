defmodule Needlist.Repo.Job do
  @moduledoc """
  Core module for querying `Oban.Job` records.
  """

  import Ecto.Query

  alias Oban.Job

  @spec base_query :: Ecto.Query.t()
  def base_query do
    from(Job)
  end

  @spec by_state(query :: Ecto.Query.t(), state :: String.t()) :: Ecto.Query.t()
  def by_state(query, state) do
    where(query, [j], j.state == ^state)
  end

  @spec by_queue(query :: Ecto.Query.t(), queue :: String.t()) :: Ecto.Query.t()
  def by_queue(query, queue) do
    where(query, [j], j.queue == ^queue)
  end

  @spec ordered_by_completed_at(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def ordered_by_completed_at(query) do
    order_by(query, [j], desc_nulls_last: j.completed_at)
  end

  @spec by_username_arg(query :: Ecto.Query.t(), username :: String.t()) :: Ecto.Query.t()
  def by_username_arg(query, username) do
    where(query, [j], fragment("?->>'username'", j.args) == ^username)
  end

  @spec last_completed_for_queue(queue :: String.t()) :: Ecto.Query.t()
  def last_completed_for_queue(queue) do
    base_query()
    |> by_state("completed")
    |> by_queue(queue)
    |> ordered_by_completed_at()
    |> first()
  end
end
