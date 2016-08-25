defmodule Greenbar.DirectivesGenerator do

  def generate(outputs) do
    outputs = consolidate_outputs(outputs)
    Enum.map(outputs, &render_output/1)
  end

  defp render_output(output) when is_binary(output) do
    Earmark.to_html(output, %Earmark.Options{breaks: true, smartypants: false,
                                             renderer: Greenbar.DirectiveRenderer})
  end

  defp consolidate_outputs(outputs) do
    {globals, current} = Enum.reduce(outputs, {[], ""}, &combine_outputs/2)
    globals = if current != "" do
      [current|globals]
    else
      globals
    end
    Enum.reverse(globals)
  end

  defp combine_outputs(output, {globals, current}) when is_binary(output) do
    {globals, :erlang.iolist_to_binary([current, output])}
  end
  defp combine_outputs(output, {globals, current}) do
    globals = if current != "" do
      [current|globals]
    else
      globals
    end
    {[output|globals], ""}
  end

end
