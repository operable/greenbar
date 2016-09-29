defmodule Greenbar.DirectivesGenerator do

  def generate(outputs) do
    outputs
    |> process_markdown
    |> drop_trailing_newline
    |> combine_text_nodes
    |> Enum.flat_map(&split_newline/1)
  end

  defp process_markdown(outputs) do
    Enum.flat_map(outputs, &parse_markdown/1)
  end

  defp parse_markdown(%{name: :attachment, children: children}=attachment) do
    updated = generate(children)
    [Map.put(attachment, :children, updated)]
  end
  defp parse_markdown(%{name: :text, text: text}) do
    {:ok, parsed} = :greenbar_markdown.analyze(text)
    if String.contains?(text, "\n") do
      parsed
    else
      Enum.filter(parsed, &(Map.get(&1, :name) != :newline))
    end
  end
  defp parse_markdown(value), do: [value]

  defp make_text_node(""), do: %{name: :newline}
  defp make_text_node(text), do: %{name: :text, text: text}

  defp drop_trailing_newline([]), do: []
  defp drop_trailing_newline(result) do
    case :lists.last(result) do
      %{name: :newline} ->
        Enum.slice(result, 0, Enum.count(result) - 1)
      _ ->
        result
    end
  end

  defp combine_text_nodes(nodes) do
    Enum.reduce(nodes, [], &combine_text_nodes/2) |> Enum.reverse
  end
  defp combine_text_nodes(value, []), do: [value]
  defp combine_text_nodes(%{name: :text, text: t2text}, [%{name: :text, text: t1text}|t]) do
    combined = %{name: :text, text: Enum.join([t1text, t2text])}
    [combined|t]
  end
  defp combine_text_nodes(value, accum), do: [value|accum]

  defp split_newline(%{name: :attachment, children: children}=attachment) do
    [%{attachment | children: Enum.flat_map(children, &split_newline/1)}]
  end
  defp split_newline(%{name: :text, text: text}) do
    case String.split(text, "\n", trim: true) do
      [^text] ->
        [%{name: :text, text: text}]
      [partial] ->
        [%{name: :newline}, %{name: :text, text: partial}]
      items ->
        items |> Enum.map(&make_text_node/1) |> Enum.intersperse(%{name: :newline})
    end
  end
  defp split_newline(item), do: [item]

end
