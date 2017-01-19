defmodule Greenbar.DirectivesGenerator do

  def generate(outputs) do
    outputs
    |> process_markdown
    |> post_process
  end

  defp process_markdown(outputs) do
    Enum.flat_map(outputs, &parse_markdown/1)
  end

  defp parse_markdown(%{"name" => "attachment", "children" => children}=attachment) do
    updated = generate(children)
    [Map.put(attachment, "children", updated)]
  end
  defp parse_markdown(%{"name" => "text", "text" => text}) do
    {:ok, parsed} = :greenbar_markdown.analyze(text)
    parsed
  end
  defp parse_markdown(value), do: [value]

  defp make_text_node(text), do: %{"name" => "text", "text" => text}

  defp post_process(nodes) do
    nodes
    |> combine_text_nodes([])
    |> parse_newlines([])
  end

  defp combine_text_nodes([], accum), do: Enum.reverse(accum)
  defp combine_text_nodes([%{"children" => children}=node|rest], accum) do
    node = Map.put(node, "children", post_process(children))
    combine_text_nodes(rest, [node|accum])
  end
  defp combine_text_nodes([%{"name" => "text", "text" => t2text}|rest], [%{"name" => "text", "text" => t1text}=t1|accum]) do
    t1 = Map.put(t1, "text", "#{t1text}#{t2text}")
    combine_text_nodes(rest, [t1|accum])
  end
  defp combine_text_nodes([node|rest], accum) do
    combine_text_nodes(rest, [node|accum])
  end

  defp parse_newlines([], accum), do: Enum.reverse(accum)
  defp parse_newlines([%{"children" => children}=node|rest], accum) do
    node = Map.put(node, "children", parse_newlines(children, []))
    parse_newlines(rest, [node|accum])
  end
  defp parse_newlines([%{"name" => "text", "text" => text}=t1|rest], accum) do
    split_text = text |> String.split("\n") |> Enum.reject(&(&1 == ""))
    case split_text do
      [^text] ->
        parse_newlines(rest, [t1|accum])
      [partial] ->
        parse_newlines(rest, [make_text_node(partial), %{"name" => "newline"}] ++ accum)
      items ->
        parsed = items |> Enum.map(&make_text_node/1) |> Enum.intersperse(%{"name" => "newline"}) |> Enum.reverse
        parse_newlines(rest, parsed ++ accum)
    end
  end
  defp parse_newlines([node|rest], accum) do
    parse_newlines(rest, [node|accum])
  end

end
