defmodule Greenbar do

  alias Greenbar.Engine
  alias Greenbar.DirectivesGenerator
  alias Piper.Common.Scope

  def eval(template, scope \\ %{}) do
    {:ok, engine} = Engine.default()
    case :greenbar_template_parser.scan_and_parse(template) do
      {:ok, parsed} ->
        case expand_tags(parsed, engine, scope) do
          {:ok, outputs} ->
            DirectivesGenerator.generate(outputs)
          error ->
            error
        end
      error ->
        error
    end
  end

  defp expand_tags(parsed, engine, scope) do
    scope = Scope.from_map(scope)
    case Greenbar.Exec.Interpret.run(parsed, engine, scope) do
      {:ok, outputs, _} ->
        {:ok, :lists.flatten(outputs)}
      error ->
        error
    end
  end

end
