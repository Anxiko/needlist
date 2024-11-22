defmodule Needlist.Repo.User.Oauth do
  @moduledoc false

  use Ecto.Schema

  alias Ecto.Changeset

  @required [:token, :token_secret]
  @optional [:inserted_at, :updated_at]

  @type t() :: %__MODULE__{
          token: String.t(),
          token_secret: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key false
  embedded_schema do
    field :token, :string
    field :token_secret, :string
    timestamps()
  end

  use EctoExtra.SchemaType, schema: __MODULE__

  @spec changeset(oauth :: t() | %__MODULE__{}, params :: map()) :: Changeset.t(t())
  def changeset(oauth \\ %__MODULE__{}, params) do
    oauth
    |> Changeset.cast(params, @required ++ @optional)
    |> Changeset.validate_required(@required)
  end

  @spec new :: %__MODULE__{}
  def new, do: %__MODULE__{}
end
