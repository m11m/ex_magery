defmodule ExMagery.Compile do
  import ExMagery.Html, only: [boolean_attribute?: 1]

  def compile_templates(templates_file_path) do
    quoted =
      File.read!(templates_file_path)
      |> Floki.parse()
      |> Floki.filter_out(:comment)
      |> (fn ds -> if is_tuple(ds), do: [ds], else: ds end).()
      |> Enum.reduce(%{}, fn tree, acc ->
        Map.put(acc, tagname(tree), tag_attr_to_tag(tree))
      end)
      |> Map.get("app-main")
      |> mgy_to_eex_variables()
      |> mgy_to_eex_if()
      |> List.first()
      |> Floki.raw_html()
      |> unescape_eex_pieces
      |> EEx.compile_string()

    {:ok, %{"app-main" => quoted}}
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

  defp mgy_to_eex_if({tag, attributes, children}) do
    data_if =
      Enum.reduce(attributes, nil, fn attr, acc ->
        case is_tuple(attr) and elem(attr, 0) == "data-if" do
          true ->
            elem(attr, 1)

          false ->
            acc
        end
      end)

    attributes =
      Enum.reduce(attributes, [], fn attr, acc ->
        case is_tuple(attr) and elem(attr, 0) == "data-if" do
          true ->
            acc

          false ->
            acc ++ [attr]
        end
      end)

    children =
      Enum.map(children, fn child ->
        cond do
          is_tuple(child) ->
            mgy_to_eex_if(child)

          true ->
            child
        end
      end)
      |> List.flatten()

    case data_if == nil do
      false ->
        [
          "<%=
            value = if Keyword.has_key?(binding(), String.to_atom(\"#{String.trim(data_if)}\")) do
              Code.eval_string(\"#{String.trim(data_if)}\", binding()) |> elem(0)
            else
              nil
            end

            if !!value and value != 0 and value != \"\" and value != [] do %>",
          {tag, attributes, children},
          "<% end %>"
        ]

      true ->
        [{tag, attributes, children}]
    end
  end

  defp mgy_to_eex_variables({tag, attributes, children}) do
    children =
      Enum.map(children, fn c ->
        cond do
          is_binary(c) ->
            mgy_variables_from_string(c)

          is_tuple(c) ->
            mgy_to_eex_variables(c)

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
    case String.split(string, ~r({{|}})) do
      [first, second, third] ->
        "#{first}<%=
          if Keyword.has_key?(binding(), String.to_atom(\"#{String.trim(second)}\")) do
            Code.eval_string(\"#{String.trim(second)}\", binding()) |> elem(0)
          else
            \"\"
          end
          %>#{third}"

      [first] ->
        first
    end
  end

  defp unescape_eex_pieces(html) do
    html
    |> String.replace("&lt;%", "<%")
    |> String.replace("&lt;%=", "<%=")
    |> String.replace("%&gt;", "%>")
    |> String.replace("&quot;", "\"")
    |> String.replace("&gt;", ">")
  end

  defp tag_attr_to_tag(html_tree) do
    {_, attributes, children} = html_tree

    tagname = tagname(html_tree)

    attributes = Enum.reject(attributes, fn {n, _} -> n == "data-tagname" end)

    {tagname, attributes, children}
  end

  defp tagname(html) do
    Floki.attribute(html, "template", "data-tagname")
    |> List.first()
  end
end
