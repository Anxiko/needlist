defmodule WantQuery do
  require Logger

  defp get_labels(%{"basic_information" => %{"labels" => labels}}) when is_list(labels) do
    labels
  end

  defp get_labels(want) do
    Logger.warning("No labels in #{want}")
    []
  end

  def all_labels_present(want) do
    want
    |> get_labels()
    |> Enum.all?(&Map.get(&1, "catno"))
  end
end

".payloads/wants.json"
|> File.read!()
|> Jason.decode!()
|> Map.fetch!("wants")
|> Enum.filter(&not WantQuery.all_labels_present(&1))
# |> Enum.filter(fn %{"basic_information" => %{"labels" => labels}} -> length(labels) > 1 end)
|> IO.inspect()
