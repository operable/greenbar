defimpl Greenbar.Exec.Interpret, for: [Greenbar.Ast.Template,
                                       Greenbar.Ast.TagBody] do

  alias Greenbar.Exec.Interpret
  alias Piper.Common.Ast

  def run(template, engine, scope) do
    case run_statements(template.statements, engine, scope, []) do
      {:ok, outputs, scope} ->
        {:ok, outputs, scope}
      error ->
        error
    end
  end

  defp run_statements([], _engine, scope, accum) do
    {:ok, Enum.reverse(accum), scope}
  end
  defp run_statements([statement|t], engine, scope, accum) do
    case Interpret.run(statement, engine, scope) do
      {:ok, output, scope} ->
        run_statements(t, engine, scope, [convert_output(output)|accum])
      error ->
        error
    end
  end

  defp convert_output(%Ast.Variable{}=output), do: "#{output}"
  defp convert_output(output), do: output

end
