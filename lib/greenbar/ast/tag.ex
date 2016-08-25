defmodule Greenbar.Ast.TagBody do

  defstruct [:statements]

  def new(statements) do
    %__MODULE__{statements: statements}
  end

end

defmodule Greenbar.Ast.Tag do

  alias Greenbar.Ast.TagBody

  defstruct [:tag, :attributes, :body]

  def new(tag, attributes \\ %{}) when is_binary(tag) do
    attributes = if is_list(attributes) do
      Enum.reduce(attributes, %{}, fn({key, value}, acc) -> Map.put(acc, key, value) end)
    else
      attributes
    end
    %__MODULE__{tag: tag, attributes: attributes}
  end

  def body(%__MODULE__{}=tag, body) do
    body = strip_leading_newline(body)
    %{tag | body: body}
  end

  def body?(%__MODULE__{body: nil}), do: false
  def body?(%__MODULE__{}), do: true

  defp strip_leading_newline(%TagBody{statements: [%Greenbar.Ast.Text{text: text}|t]}=body) do
    case String.trim(text) do
      "" ->
        %{body | statements: t}
      _ ->
        body
    end
  end

end
