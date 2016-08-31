defmodule Greenbar.DirectivesGenerator do

  def generate(outputs) do
    IO.inspect outputs, pretty: true
    Enum.flat_map(outputs, &process_markdown/1)
  end

  defp process_markdown(%{name: :text, text: text}) do
    {:ok, parsed} = Greenbar.Markdown.parse(text)
    Enum.reverse(parsed) |> Enum.flat_map(&manually_split_newlines/1)
  end
  defp process_markdown(node), do: [node]

  defp manually_split_newlines(%{name: :text, text: text}) do
    text
    |> String.split("\n")
    |> Enum.map(&make_text_node/1)
    |> Enum.intersperse(%{name: :newline})
  end
  defp manually_split_newlines(node), do: [node]

  defp make_text_node(""), do: %{name: :newline}
  defp make_text_node(text), do: %{name: :text, text: text}
end
