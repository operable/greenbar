defimpl Greenbar.Exec.Interpret, for: Greenbar.Ast.Tag do

  alias Greenbar.Engine
  alias Greenbar.Exec.Interpret
  alias Greenbar.Ast.Tag

  def run(tag, engine, scope) do
    if Tag.body?(tag) do
      run_with_body(tag, engine, scope, [])
    else
      run_tag(tag, engine, scope)
    end
  end

  defp run_tag(tag, engine, scope) do
    IO.inspect tag.attributes, pretty: true
    case run_attributes(Map.keys(tag.attributes), tag.attributes, engine, scope, %{}) do
      {:ok, attributes, scope} ->
        case Engine.get_tag(engine, tag.tag) do
          nil ->
            {:error, "Unknown tag '#{tag.tag}'"}
          tag_mod ->
            case tag_mod.render(attributes, scope) do
              {:halt, output, _} ->
                {:ok, output, scope}
              error ->
                error
            end
        end
    end
  end

  defp run_with_body(tag, engine, scope, accum) do
    case run_attributes(Map.keys(tag.attributes), tag.attributes, engine, scope, %{}) do
      {:ok, attributes, scope} ->
        case Engine.get_tag(engine, tag.tag) do
          nil ->
            {:error, "Unknown tag '#{tag.tag}'"}
          tag_mod ->
            case tag_mod.render(attributes, scope) do
              {:cont, output, scope, body_scope} ->
                accum = if output == nil do
                    accum
                  else
                    accum ++ output
                  end
                case Interpret.run(tag.body, engine, body_scope) do
                  {:ok, nil, _} ->
                    run_with_body(tag, engine, scope, accum)
                  {:ok, output, _} ->
                    run_with_body(tag, engine, scope, accum ++ output)
                  error ->
                    error
                end
              {:halt, output, scope} ->
                if output == nil do
                  {:ok, accum, scope}
                else
                  {:ok, accum ++ output, scope}
                end
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
  defp evaluate_attribute_values(val, engine, scope, accum) do
    case Interpret.run(val, engine, scope) do
      {:ok, result, scope} ->
        {:ok, accum ++ [result], scope}
      error ->
        error
    end
  end

end
