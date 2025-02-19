defmodule Needlist.Repo.Want.Label do
  @moduledoc """
  Label attributed to a release.
  """

  use Ecto.Schema

  alias Ecto.Changeset

  @derive EctoExtra.DumpableSchema

  @label_catno_joiner "–"

  @required_fields [:id, :name, :catno, :resource_url]
  @optional_fields []
  @fields @required_fields ++ @optional_fields

  @primary_key false
  embedded_schema do
    field :id, :id, primary_key: false
    field :name, :string
    field :catno, :string
    field :resource_url, :string
  end

  @type t() :: %__MODULE__{
          id: integer(),
          name: String.t(),
          catno: String.t(),
          resource_url: String.t()
        }

  @spec changeset(t(), map()) :: Changeset.t(t())
  @spec changeset(t()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
  end

  @spec display_name(t()) :: String.t()
  def display_name(%__MODULE__{name: name, catno: catno}) do
    "#{name} #{@label_catno_joiner} #{catno}"
  end

  @spec display_labels([t()]) :: String.t()
  def display_labels(labels) do
    label_names = Enum.map_join(labels, ", ", fn %__MODULE__{name: name} -> String.downcase(name) end)
    label_catnos = Enum.map_join(labels, ", ", fn %__MODULE__{catno: catno} -> String.downcase(catno) end)

    "#{label_names} #{@label_catno_joiner} #{label_catnos}"
  end

  @spec display_catnos([t()]) :: String.t()
  def display_catnos(labels) do
    Enum.map_join(labels, ", ", fn %__MODULE__{catno: catno} -> String.downcase(catno) end)
  end
end
