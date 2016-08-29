defmodule Greenbar.DirectivesGenerator do

  def generate(outputs) do
    outputs
    |> Enum.map(&render_output/1)
    |> :lists.flatten
    |> consolidate_outputs
  end

  defp render_output(%{name: :text, text: output}) when is_binary(output) do
    Earmark.to_html(output, %Earmark.Options{smartypants: false,
                                             renderer: Greenbar.DirectiveRenderer})
  end
  defp render_output(%{name: :eol}), do: %{name: "newline"}

  defp consolidate_outputs(outputs) do
    consolidated = consolidate_outputs(outputs, [])
    if length(consolidated) < length(outputs) do
      consolidate_outputs(consolidated)
    else
      consolidated
    end
  end

  defp consolidate_outputs([], accum), do: Enum.reverse(accum)
  defp consolidate_outputs([%{name: "text", text: h1t}, %{name: "text", text: h2t}|t], accum) do
    consolidate_outputs(t, [%{name: "text", text: Enum.join([h1t, h2t])}|accum])
  end
  defp consolidate_outputs([h|t], accum), do: consolidate_outputs(t, [h|accum])

end
