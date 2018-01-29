defmodule ExMagery do
  defdelegate compile_templates(templates_file_path), to: ExMagery.Compile

  def render_to_string(data, templates, template_name \\ "app-main") do
    rendered =
      templates[template_name]
      |> Code.eval_quoted(data_to_kwls(data))
      |> elem(0)

    {:ok, rendered}
  end

  defp template_node?(node, trees_map) do
    is_tuple(node) and Map.fetch(trees_map, elem(node, 0)) == :ok
  end

  defp data_to_kwls(data) do
    Map.to_list(data)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end
end
