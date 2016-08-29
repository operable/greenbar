defmodule Greenbar.DirectivesGenerator do

  def generate(outputs) do
    outputs
    |> Enum.map(&render_output/1)
    |> consolidate_outputs
  end

  defp render_output(%{name: :text, text: output}) when is_binary(output) do
    Earmark.to_html(output, %Earmark.Options{breaks: true, smartypants: false,
                                             renderer: Greenbar.DirectiveRenderer})
  end
  defp render_output(%{name: :eol}), do: %{name: "newline"}

  defp consolidate_outputs(outputs) do
    {globals, current} = Enum.reduce(outputs, {[], nil}, &combine_outputs/2)
    Enum.reverse([current|globals])
  end

  defp combine_outputs(%{name: :text, text: output}, {globals, %{name: :text, text: current}}) do
    {globals, Enum.join([current, output])}
  end
  defp combine_outputs(output, {globals, nil}), do: {globals, output}
  defp combine_outputs(output, {globals, current}), do: {[current|globals], output}

end
