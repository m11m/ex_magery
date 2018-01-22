defmodule ExMagery do
  @boolean_attributes ~w(
    allowfullscreen
    async
    autofocus
    autoplay
    capture
    checked
    controls
    default
    defer
    disabled
    formnovalidate
    hidden
    itemscope
    loop
    multiple
    muted
    novalidate
    open
    readonly
    reversed
    required
    selected
  )

  def compile_templates(templates_file_path) do
    trees_list =
      File.read!(templates_file_path)
      |> Floki.parse()
      |> Floki.filter_out(:comment)
      |> (fn ds -> if is_tuple(ds), do: [ds], else: ds end).()

    #    |> Apex.ap

    trees_map =
      for tree <- trees_list, into: %{} do
        tagname = tagname(tree)
        tree = tag_attr_to_tag(tree)
        {tagname, tree}
      end

    quoted =
      trees_map["app-main"]
      |> mgy_to_eex_variables(trees_map)
      |> Floki.raw_html()
      |> EEx.compile_string()

    {:ok, %{"app-main" => quoted}}
  end



  def render_to_string(data, templates, template_name \\ "app-main") do
    rendered = templates[template_name]
    |> Code.eval_quoted(data_to_kwls(data))
    |> elem(0)

    {:ok, rendered}
  end




  defp transform_floki_boolean_attributes(html_tree) do
    Floki.map(html_tree, fn {tag, attrs} ->
      attrs = Enum.map(attrs, fn {k, v} -> if k == v, do: {k}, else: {k, v} end)
      {tag, attrs} |> Apex.ap()
    end)
  end

  def boolean_attribute?(attribute_name) do
    Enum.member?(@boolean_attributes, attribute_name)
  end

  defp tagname(html) do
    Floki.attribute(html, "template", "data-tagname")
    |> List.first()
  end

  defp template_node?(node, trees_map) do
    #    Apex.ap Map.fetch(trees_map, elem(node, 0))
    is_tuple(node) and Map.fetch(trees_map, elem(node, 0)) == :ok
  end

  defp tag_attr_to_tag(html_tree) do
    {_, attributes, children} = html_tree

    tagname = tagname(html_tree)

    attributes = Enum.reject(attributes, fn {n, _} -> n == "data-tagname" end)

    {tagname, attributes, children}
  end

  defp mgy_to_eex_variables({tag, attributes, children}, trees_map) do
    children =
      Enum.map(children, fn c ->
        cond do
          is_binary(c) ->
            mgy_variables_from_string(c)

          template_node?(c, trees_map) ->
            c

          is_tuple(c) ->
            mgy_to_eex_variables(c, trees_map)

          true ->
            c
        end
      end)

    attributes =
      Enum.map(attributes, fn attr ->
        {k, v} = attr

        cond do
          boolean_attribute?(k) ->
            mgy_boolean_attribute_variables_from_string(k, v)

          true ->
            {k, mgy_variables_from_string(v)}
        end
      end)

    {tag, attributes, children}
  end

  defp mgy_variables_from_string(string) do
    String.split(string, ~r({{|}}))
    |> Enum.reduce([], fn s, acc ->
      if length(acc) == 2 do
        ["#{Enum.at(acc, 0)}<%=
          if Keyword.has_key?(binding(), String.to_atom(\"#{Enum.at(acc, 1)}\")) do
            Code.eval_string(\"#{Enum.at(acc, 1)}\", binding()) |> elem(0)
          else
            \"\"
          end
          %>#{s}"]
      else
        acc ++ [s]
      end
    end)
    |> List.first()
  end

  defp mgy_boolean_attribute_variables_from_string(k, k), do: k

  defp mgy_boolean_attribute_variables_from_string(k, v) do
    split = String.split(v, ~r({{|}}))

    case length(split) do
      1 ->
        k

      _ ->
        varname = Enum.at(split, 1) |> String.trim()
        "<%=
          if Keyword.has_key?(binding(), String.to_atom(\"#{varname}\")) do
            Code.eval_string(\"#{varname}\", binding())
            |> elem(0)
            |> fn (v) ->
              if v do
                \"#{k}\"
              end
            end.()
          end
        %>"
    end
  end

  defp data_to_kwls(data) do
    Map.to_list(data)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    #    |> IO.inspect
  end
end
