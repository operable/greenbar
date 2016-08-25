defimpl Greenbar.Exec.Interpret, for: Greenbar.Ast.Text do

  def run(text, _engine, scope) do
    {:ok, text.text, scope}
  end

end
