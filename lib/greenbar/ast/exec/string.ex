defimpl Greenbar.Exec.Interpret, for: Piper.Common.Ast.String do

  def run(string, _engine, scope) do
    {:ok, string.value, scope}
  end

end
