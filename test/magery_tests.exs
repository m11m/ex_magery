defmodule MageryTests do
  @magery_tests_path "test/magery-tests/"

  defmacro __using__(_opts) do
    File.ls!(File.cwd!() <> "/#{@magery_tests_path}components")
#    |> Enum.filter(fn (path) -> String.contains?(path, "0109") end)
    |> Enum.sort()
    |> Enum.map(&MageryTests.build_test_ast/1)
  end

  def build_test_ast(component_dirname) do
    component_path = "#{@magery_tests_path}components/#{component_dirname}"

    quote do
      test unquote(component_path) do
        error = File.read!(unquote("#{component_path}/error.txt"))

        {_status, templates} = ExMagery.compile_templates(unquote("#{component_path}/template.html"))

        data = Poison.decode!(File.read!(unquote("#{component_path}/data.json")))

        {status, render_result} =
          ExMagery.render_to_string(data, templates)

        expected =
          unquote("#{component_path}/expected.html")
          |> File.read!()
          |> Floki.parse()
          |> Floki.raw_html()

        case status do
          :ok ->
            assert expected == Floki.parse(render_result) |> Floki.raw_html()
          :error ->
            assert error == render_result
        end
      end
    end
  end
end
