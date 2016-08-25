defimpl Greenbar.Exec.Interpret, for: Greenbar.Ast.Tag do

  alias Greenbar.Engine
  alias Greenbar.Exec.Interpret

  alias Piper.Common.Scope
  alias Piper.Common.Scope.Scoped

  def run(tag, engine, scope) do
    case run_attributes(Map.keys(tag.attributes), tag.attributes, engine, scope, %{}) do
      {:ok, attributes, scope} ->
        child_scope = Scope.empty_scope()
        Scoped.set_parent(child_scope, scope)
        case Engine.get_tag(engine, tag.tag) do
          nil ->
            {:error, "Unknown tag '#{tag.tag}'"}
          tag_mod ->
            case tag_mod.render(attributes, child_scope) do
              {:halt, output, _} ->
                {:ok, output, scope}
              error ->
                error
            end
        end
    end
  end

  defp run_attributes([], _attrs, _engine, scope, accum) do
    {:ok, accum, scope}
  end
  defp run_attributes([key|t], attrs, engine, scope, accum) do
    case evaluate_attribute_values(Map.get(attrs, key), engine, scope, []) do
      {:ok, values, scope} ->
        run_attributes(t, attrs, engine, scope, Map.put(accum, key, values))
      error ->
        error
    end
  end

  defp evaluate_attribute_values([], _engine, scope, accum), do: {:ok, Enum.reverse(accum), scope}
  defp evaluate_attribute_values([val|t], engine, scope, accum) do
    case Interpret.run(val, engine, scope) do
      {:ok, result, scope} ->
        evaluate_attribute_values(t, engine, scope, [result|accum])
      error ->
        error
    end
  end

end
