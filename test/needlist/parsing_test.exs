defmodule Needlist.ParsingTest do
  alias Needlist.Wantlists
  use Needlist.DataCase

  alias Nullables.Result
  alias Needlist.Repo
  alias Needlist.Repo.Pagination
  alias Needlist.Repo.Release
  alias Needlist.Repo.User
  alias Needlist.Repo.Want
  alias Needlist.Repo.Wantlist

  @paginated_wants_response "test/fixtures/wants.json"

  defmodule Embedded do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :inner, :string
    end

    @type t() :: %__MODULE__{}

    use EctoExtra.SchemaType, schema: __MODULE__

    @spec changeset(t(), map()) :: Ecto.Changeset.t()
    @spec changeset(t()) :: Ecto.Changeset.t()
    def changeset(struct, params \\ %{}) do
      struct
      |> Ecto.Changeset.cast(params, [:inner])
      |> Ecto.Changeset.validate_required([:inner])
    end

    @spec new() :: t()
    def new() do
      %__MODULE__{}
    end
  end

  describe "embedded schema within schemaless" do
    test "embeds one" do
      changeset =
        {%{}, %{embedded: Embedded}}
        |> Ecto.Changeset.cast(%{embedded: %{inner: "inner"}}, [:embedded])

      assert changeset.valid?
    end

    test "embeds many" do
      changeset =
        {%{}, %{embedded: {:array, Embedded}}}
        |> Ecto.Changeset.cast(%{embedded: [%{inner: "inner"}]}, [:embedded])

      assert changeset.valid?
    end
  end

  describe "parsing from a response of paginated items" do
    setup do
      user =
        %User{}
        |> User.changeset(%{id: 1, username: "test"})
        |> Repo.insert!()

      {:ok, %{user: user}}
    end

    test "just one want entry" do
      parse_result =
        @paginated_wants_response
        |> File.read!()
        |> Jason.decode!()
        |> Map.fetch!("wants")
        |> List.first()
        |> then(&Want.changeset(Want.new(), &1))
        |> Ecto.Changeset.apply_action(:parse)

      assert {:ok, _parsed_data} = parse_result
    end

    test "all want entries" do
      raw_entries =
        @paginated_wants_response
        |> File.read!()
        |> Jason.decode!()
        |> Map.fetch!("wants")

      for raw_entry <- raw_entries do
        parse_result =
          raw_entry
          |> then(&Want.changeset(Want.new(), &1))
          |> Ecto.Changeset.apply_action(:parse)

        assert {:ok, _parsed_data} = parse_result
      end
    end

    test "the entire response" do
      parse_result =
        @paginated_wants_response
        |> File.read!()
        |> Jason.decode!()
        |> then(&Pagination.parse(&1, :wants, Want))

      assert {:ok, _parsed_data} = parse_result
    end

    test "and insert all items into the DB", %{user: %User{id: id, username: username}} do
      parse_result =
        @paginated_wants_response
        |> File.read!()
        |> Jason.decode!()
        |> then(&Pagination.parse(&1, :wants, Want))

      assert {:ok, %Pagination{items: [_ | _] = items}} = parse_result

      items
      |> Enum.map(&Release.from_want/1)
      |> Enum.map(&Result.unwrap!/1)
      |> Enum.map(&Repo.insert!/1)

      wantlists =
        items
        |> Enum.map(&Wantlist.from_scrapped_want(&1, id))
        |> Enum.map(&Result.unwrap!/1)
        |> Enum.map(&Repo.insert!/1)

      assert length(Wantlists.by_username(username)) == length(wantlists)
    end
  end
end
