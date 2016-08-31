defmodule Greenbar.DirectivesGenerator do

  def generate(outputs) do
    outputs
    |> :lists.flatten
    |> Enum.map(&process_markdown/1) |> :lists.flatten
  end

  defp process_markdown(%{name: :text, text: text}) do
    {:ok, parsed} = Greenbar.Markdown.analyze(text)
    parsed
    |> Enum.map(&manually_split_newlines/1)
    |> :lists.flatten
  end
  defp process_markdown(node), do: node

  defp manually_split_newlines(%{name: :text, text: text}) do
    text
    |> String.split("\n")
    |> Enum.map(&make_text_node/1)
  end
  defp manually_split_newlines(node), do: node

  defp make_text_node(""), do: %{name: :newline}
  defp make_text_node(text), do: %{name: :text, text: text}
end
