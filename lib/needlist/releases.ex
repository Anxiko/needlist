defmodule Needlist.Releases do
  @moduledoc """
  Context for releases
  """

  alias Needlist.Repo
  alias Needlist.Repo.Release

  @spec all :: [Release.t()]
  def all do
    Release.named_binding()
    |> Release.with_price_stats()
    |> Repo.all()
  end
end
