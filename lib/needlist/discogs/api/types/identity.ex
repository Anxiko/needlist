defmodule Needlist.Discogs.Api.Types.Identity do
  @moduledoc """
  Response type for the OAuth /identity endpoint
  """

  use Ecto.Schema

  alias Nullables.Result
  alias Ecto.Changeset

  @required [:id, :username, :resource_url, :consumer_name]
  @optional []

  @type t() :: %__MODULE__{
          id: integer(),
          username: String.t(),
          resource_url: String.t(),
          consumer_name: String.t()
        }

  @primary_key false
  embedded_schema do
    field :id, :id, primary_key: true
    field :username, :string
    field :resource_url, :string
    field :consumer_name, :string
  end

  @spec changeset(identity :: t() | %__MODULE__{}, params :: map()) :: Changeset.t(t())
  @spec changeset(params :: map()) :: Changeset.t(t())
  def changeset(identity \\ %__MODULE__{}, params) do
    identity
    |> Changeset.cast(params, @required ++ @optional)
    |> Changeset.validate_required(@required)
  end

  @spec cast(data :: map) :: Result.result(t())
  def cast(data) do
    data
    |> changeset()
    |> Changeset.apply_action(:cast)
    |> case do
      {:ok, valid_data} -> {:ok, valid_data}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end
end
