defmodule Needlist.ParsingTest do
  use ExUnit.Case

  alias Needlist.Repo.Pagination.Page
  alias Needlist.Repo.Want

  @paginated_wants_response "test/fixtures/wants.json"

  defmodule Embedded do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :inner, :string
    end

    use EctoExtra.SchemaType, schema: __MODULE__

    def changeset(struct, params \\ %{}) do
      struct
      |> IO.inspect(label: "Embedded changeset")
      |> Ecto.Changeset.cast(params, [:inner])
      |> Ecto.Changeset.validate_required([:inner])
    end

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
      schema = Page.Schema.new(:wants, Want)

      parse_result =
        @paginated_wants_response
        |> File.read!()
        |> Jason.decode!()
        |> then(&Page.parse(schema, &1))

      assert {:ok, _parsed_data} = parse_result
    end
  end
end
