defmodule Greenbar.Ast.Text do

  defstruct [:text]

  def new(text) when is_binary(text) do
    %__MODULE__{text: text}
  end

end
