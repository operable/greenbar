defmodule Greenbar.Ast.Template do

  defstruct [name: nil, file_name: nil, statements: []]

  def new(statements, names \\ []) when is_list(statements) do
    name = Keyword.get(names, :name)
    file_name = Keyword.get(names, :file_name)
    %__MODULE__{name: name, file_name: file_name, statements: statements}
  end

end
