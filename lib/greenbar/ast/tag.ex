defmodule Greenbar.Ast.TagBody do

  defstruct [:statements]

  def new(statements) when is_list(statements) do
    %__MODULE__{statements: statements}
  end

end

defmodule Greenbar.Ast.Tag do

  defstruct [:tag, :attributes, :body]

  def new(tag, attributes \\ [])
  def new(tag, attributes) when is_binary(tag) and is_list(attributes) do
    attributes = if is_list(attributes) do
      Enum.reduce(attributes, %{}, fn({key, value}, acc) -> Map.put(acc, key, value) end)
    else
      attributes
    end
    %__MODULE__{tag: tag, attributes: attributes}
  end


  def body(%__MODULE__{}=tag, body) do
    %{tag | body: body}
  end

  def body?(%__MODULE__{body: nil}), do: false
  def body?(%__MODULE__{}), do: true

end
