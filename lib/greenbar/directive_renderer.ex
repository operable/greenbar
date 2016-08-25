defmodule Greenbar.DirectiveRenderer do

  alias Earmark.Block
  import Greenbar.Markdown.Inline, only: [convert: 2]

  def render(blocks, context, mapper) do
    :lists.flatten(mapper.(blocks, &block_to_directive(&1, context, mapper)))
  end

  def em([src]), do: em(src)
  def em(src) do
    %{name: "italic", text: extract_text(src)}
  end
  def text([src]), do: text(src)
  def text(src) do
    %{name: "text", text: src}
  end
  def strong([src]), do: strong(src)
  def strong(src) do
    %{name: "bold", text: extract_text(src)}
  end
  def codespan([src]), do: codespan(src)
  def codespan(src) do
    %{name: "fixed_width", text: extract_text(src)}
  end

  def br() do
    %{name: "newline", text: "\n"}
  end

  defp block_to_directive(%Block.Para{lines: lines}, context, _mf) do
    convert(lines, context)
  end

  defp extract_text(src) when is_map(src) do
    src.text
  end
  defp extract_text(src), do: src

end
