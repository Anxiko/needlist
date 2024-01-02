defmodule Needlist.Repo do
  use Ecto.Repo,
    otp_app: :needlist,
    adapter: Ecto.Adapters.Postgres
end
