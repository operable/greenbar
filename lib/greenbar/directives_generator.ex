defmodule Greenbar.DirectivesGenerator do

  def generate(outputs) do
    outputs
    |> Enum.flat_map(&process_markdown/1)
    |> drop_trailing_newline
    |> Enum.reduce(nil, &combine_text_nodes/2)
    |> Enum.reverse
  end

  defp process_markdown(%{name: :text, text: text}) do
    {:ok, parsed} = Greenbar.Markdown.analyze(text)
    parsed
    |> Enum.flat_map(&manually_split_newlines/1)
  end
  defp process_markdown(node), do: [node]

  defp manually_split_newlines(%{name: :text, text: ""}), do: []
  defp manually_split_newlines(%{name: :text, text: "\n"}), do: [%{name: :newline}]
  defp manually_split_newlines(%{name: :text, text: text}) do
    text
    |> String.split("\n")
    |> Enum.map(&make_text_node/1)
  end
  defp manually_split_newlines(node), do: [node]

  defp make_text_node(""), do: %{name: :newline}
  defp make_text_node(text), do: %{name: :text, text: text}

  defp drop_trailing_newline(result) do
    case :lists.last(result) do
      %{name: :newline} ->
        Enum.slice(result, 0, Enum.count(result) - 1)
      _ ->
        result
    end
  end

  defp combine_text_nodes(node, nil), do: [node]
  defp combine_text_nodes(%{name: :text, text: t2text}, [%{name: :text, text: t1text}|t]) do
    combined = %{name: :text, text: Enum.join([t1text, t2text])}
    [combined|t]
  end
  defp combine_text_nodes(node, accum), do: [node|accum]

end
