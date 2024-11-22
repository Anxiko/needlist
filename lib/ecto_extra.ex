defmodule EctoExtra do
  @moduledoc """
  Some extras and helpers to work with Ecto
  """

  @validate_number_rename_option %{
    lt: :less_than,
    gt: :greater_than,
    le: :less_than_or_equal_to,
    ge: :greater_than_or_equal_to,
    eq: :equal_to,
    ne: :not_equal_to,
    msg: :message
  }

  @type embed_options() :: [atom() | {atom(), any()}]

  alias Ecto.Changeset

  @spec cast_many_embeds(changeset :: Changeset.t(schema), embeds :: [atom() | {atom(), embed_options()}]) ::
          Changeset.t(schema)
        when schema: var
  @doc """
  Utility function that casts several embeds into a changeset.
  Embeds can be provided by just their name, or in a tuple with options to forward to cast_embed/3
  """
  def cast_many_embeds(changeset, embeds) do
    embeds
    |> Enum.reduce(changeset, fn
      {embed, opts}, acc ->
        Changeset.cast_embed(acc, embed, opts)

      embed, acc ->
        Changeset.cast_embed(acc, embed)
    end)
  end

  @spec validate_number(Ecto.Changeset.t(schema), atom(), [atom() | {atom(), any()}]) :: Ecto.Changeset.t(schema)
        when schema: var
  @spec validate_number(Ecto.Changeset.t(schema), atom()) :: Ecto.Changeset.t(schema) when schema: var
  @doc """
  Easier to use version of Ecto.Changeset.validate_number/3 and Ecto.Changeset.validate_number/2
  Provides abbreviations for valid option keys, as well as abbreviations for common constraints:application
      {:lt, val} => {:less_than, val}
      {:gt, val} => {:greater_than, val}
      {:le, val} => {:less_than_or_equal_to, val}
      {:ge, val} => {:greater_than_or_equal_to, val}
      {:eq, val} => {:equal_to, val}
      {:ne, val} => {:not_equal_to, val}
      {:msg, message} => {:message, message}
      :neg => {:less_than, 0}
      :pos => {:greater_than, 0}
      :non_pos => {:less_than_or_equal_to, 0}
      :non_neg => {:greater_than_or_equal_to, 0}
      :zero => {:equal_to, 0}
      :non_zero => {:not_equal_to, 0}
  """
  def validate_number(changeset, field, opts \\ []) do
    transformed_options = Enum.map(opts, &transform_validate_number_option/1)
    Changeset.validate_number(changeset, field, transformed_options)
  end

  defp transform_validate_number_option({k, v} = entry) do
    case Map.fetch(@validate_number_rename_option, k) do
      {:ok, new_k} -> {new_k, v}
      :error -> entry
    end
  end

  defp transform_validate_number_option(:pos) do
    {:greater_than, 0}
  end

  defp transform_validate_number_option(:neg) do
    {:less_than, 0}
  end

  defp transform_validate_number_option(:zero) do
    {:equal_to, 0}
  end

  defp transform_validate_number_option(:non_zero) do
    {:not_equal_to, 0}
  end

  defp transform_validate_number_option(:non_pos) do
    {:less_than_or_equal_to, 0}
  end

  defp transform_validate_number_option(:non_neg) do
    {:greater_than_or_equal_to, 0}
  end
end
