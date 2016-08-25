defimpl Enumerable, for: [Greenbar.Ast.Template,
                          Greenbar.Ast.TagBody] do

  def count(ast) do
    if ast.statements == nil do
      {:ok, 0}
    else
      {:ok, length(ast.statements)}
    end
  end

  def member?(ast, element) do
    {:ok, Enum.member?(ast.statements, element)}
  end

  def reduce(_,       {:halt, acc}, _fun),   do: {:halted, acc}
  def reduce(ast, acc, fun) when is_map(ast) do
    reduce(ast.statements, acc, fun)
  end
  def reduce([], {:cont, acc}, _fun) do
    {:done, acc}
  end
  def reduce(statements, {:suspend, acc}, fun) when is_list(statements) do
    {:suspended, acc, &reduce(statements, &1, fun)}
  end
  def reduce([h | t], {:cont, acc}, fun) do
    reduce(t, fun.(h, acc), fun)
  end

end
