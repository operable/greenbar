defimpl Greenbar.Exec.Interpret, for: Piper.Common.Ast.Variable do

  alias Piper.Common.Scope

  def run(var, _engine, scope) do
    case Scope.bind(var, scope) do
      {:ok, bound, scope} ->
        {:ok, bound.value, scope}
      error ->
        error
    end
  end

end
