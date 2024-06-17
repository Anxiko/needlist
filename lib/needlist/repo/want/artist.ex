defmodule Needlist.Repo.Want.Artist do
  use Ecto.Schema

  alias Ecto.Changeset

  @required_fields [:id, :name, :resource_url]
  @optional_fields [:join, :anv]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  embedded_schema do
    field :id, :id, primary_key: true
    field :name, :string
    field :anv, :string
    field :resource_url, :string
    field :join, :string, default: nil
  end

  @type t() :: %__MODULE__{
          id: integer(),
          name: String.t(),
          anv: String.t() | nil,
          resource_url: String.t(),
          join: String.t() | nil
        }

  @spec changeset(t(), map()) :: Changeset.t(t())
  @spec changeset(t()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
  end

  @spec display_name(t()) :: String.t()
  def display_name(%__MODULE__{anv: anv}) when anv != nil, do: anv
  def display_name(%__MODULE__{name: name}), do: name

  @spec display_artists([t()]) :: String.t()
  def display_artists(artists) do
    artists
    |> Enum.map(fn artist ->
      display_name(artist) <> joiner(artist)
    end)
    |> Enum.join()
  end

  defp joiner(%__MODULE__{join: nil}), do: ""
  defp joiner(%__MODULE__{join: join}), do: " #{join} "
end
